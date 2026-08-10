import 'package:fl_moe/core/storage/app_directories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDirectories', () {
    test('uses XDG defaults and the isolated Fl-Moe namespace on Linux', () {
      final directories = AppDirectories.fromEnvironment(
        operatingSystem: 'linux',
        environment: const <String, String>{'HOME': '/home/moe'},
        separator: '/',
      );

      expect(directories.config, '/home/moe/.config/Fl-Moe');
      expect(directories.data, '/home/moe/.local/share/Fl-Moe');
      expect(directories.cache, '/home/moe/.cache/Fl-Moe');
      expect(directories.hive, '/home/moe/.local/share/Fl-Moe/Hive');
    });

    test('respects explicit XDG roots', () {
      final directories = AppDirectories.fromEnvironment(
        operatingSystem: 'linux',
        environment: const <String, String>{
          'HOME': '/home/moe',
          'XDG_CONFIG_HOME': '/state/config',
          'XDG_DATA_HOME': '/state/data',
          'XDG_CACHE_HOME': '/state/cache',
        },
        separator: '/',
      );

      expect(directories.config, '/state/config/Fl-Moe');
      expect(directories.data, '/state/data/Fl-Moe');
      expect(directories.cache, '/state/cache/Fl-Moe');
    });

    test('uses roaming configuration and local data on Windows', () {
      final directories = AppDirectories.fromEnvironment(
        operatingSystem: 'windows',
        environment: const <String, String>{
          'USERPROFILE': r'C:\Users\Moe',
          'APPDATA': r'C:\Users\Moe\AppData\Roaming',
          'LOCALAPPDATA': r'C:\Users\Moe\AppData\Local',
        },
        separator: r'\',
      );

      expect(directories.config, r'C:\Users\Moe\AppData\Roaming\Fl-Moe');
      expect(directories.data, r'C:\Users\Moe\AppData\Local\Fl-Moe');
      expect(directories.cache, r'C:\Users\Moe\AppData\Local\Fl-Moe\Cache');
      expect(directories.hive, r'C:\Users\Moe\AppData\Local\Fl-Moe\Hive');
    });
  });
}
