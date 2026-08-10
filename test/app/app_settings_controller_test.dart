import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/settings/app_settings_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to concept source, system theme, and right controls', () {
    final controller = AppSettingsController.load(MemoryKeyValueStore());

    expect(controller.themePreference, AppThemePreference.system);
    expect(controller.themeMode, ThemeMode.system);
    expect(controller.windowControlSide, WindowControlSide.right);
    expect(controller.accentColor, const Color(0xFF4C9BE8));
    expect(controller.clientVariant, KugouClientVariant.lite);
  });

  test('persists strongly typed setting wire values', () async {
    final store = MemoryKeyValueStore();
    final controller = AppSettingsController.load(store);

    controller
      ..setThemePreference(AppThemePreference.dark)
      ..setWindowControlSide(WindowControlSide.left)
      ..setAccentColor(const Color(0xFFEC6F9B))
      ..setClientVariant(KugouClientVariant.standard);
    await Future<void>.delayed(Duration.zero);

    final restored = AppSettingsController.load(store);
    expect(restored.themePreference, AppThemePreference.dark);
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.windowControlSide, WindowControlSide.left);
    expect(restored.accentColor, const Color(0xFFEC6F9B));
    expect(restored.clientVariant, KugouClientVariant.standard);
  });
}
