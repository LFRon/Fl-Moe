import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/storage/key_value_store.dart';
import '../../kugou_api.dart';
import '../player/playback_quality.dart';

enum AppThemePreference { system, light, dark }

enum WindowControlSide { left, right }

final class AppSettingsController extends GetxController {
  AppSettingsController._(
    this._store,
    this._themePreference,
    this._windowControlSide,
    this._accentColorValue,
    this._clientVariant,
    this._maximumPlaybackQuality,
  );

  factory AppSettingsController.load(KeyValueStore store) {
    return AppSettingsController._(
      store,
      _enumByName(
        AppThemePreference.values,
        store.read(_themeKey),
        AppThemePreference.system,
      ),
      _enumByName(
        WindowControlSide.values,
        store.read(_windowControlsKey),
        WindowControlSide.right,
      ),
      _readInt(store.read(_accentKey)) ?? 0xFF4C9BE8,
      _enumByName(
        KugouClientVariant.values,
        store.read(_clientVariantKey),
        KugouClientVariant.lite,
      ),
      normalizeSelectablePlaybackQuality(
        _enumByName(
          KugouPlaybackQuality.values,
          store.read(_maximumPlaybackQualityKey),
          KugouPlaybackQuality.standard,
        ),
      ),
    );
  }

  static const String _themeKey = 'theme';
  static const String _windowControlsKey = 'window_controls';
  static const String _accentKey = 'accent_color';
  static const String _clientVariantKey = 'kugou_client_variant';
  static const String _maximumPlaybackQualityKey = 'maximum_playback_quality';

  final KeyValueStore _store;
  AppThemePreference _themePreference;
  WindowControlSide _windowControlSide;
  int _accentColorValue;
  KugouClientVariant _clientVariant;
  KugouPlaybackQuality _maximumPlaybackQuality;

  AppThemePreference get themePreference => _themePreference;
  WindowControlSide get windowControlSide => _windowControlSide;
  Color get accentColor => Color(_accentColorValue);
  KugouClientVariant get clientVariant => _clientVariant;
  KugouPlaybackQuality get maximumPlaybackQuality => _maximumPlaybackQuality;

  ThemeMode get themeMode => switch (_themePreference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  void setThemePreference(AppThemePreference value) {
    if (_themePreference == value) return;
    _themePreference = value;
    update();
    unawaited(_store.write(_themeKey, value.name));
  }

  void setWindowControlSide(WindowControlSide value) {
    if (_windowControlSide == value) return;
    _windowControlSide = value;
    update();
    unawaited(_store.write(_windowControlsKey, value.name));
  }

  void setAccentColor(Color value) {
    if (_accentColorValue == value.toARGB32()) return;
    _accentColorValue = value.toARGB32();
    update();
    unawaited(_store.write(_accentKey, _accentColorValue));
  }

  void setMaximumPlaybackQuality(KugouPlaybackQuality value) {
    final normalized = normalizeSelectablePlaybackQuality(value);
    if (_maximumPlaybackQuality == normalized) return;
    _maximumPlaybackQuality = normalized;
    update();
    unawaited(_store.write(_maximumPlaybackQualityKey, normalized.name));
  }

  /// Saves the client variant that will be used on the next application start.
  ///
  /// The running [MusicBackend] is intentionally not touched here. Persist
  /// first so the UI never advertises a value that Hive failed to store.
  Future<void> setClientVariant(KugouClientVariant value) async {
    if (_clientVariant == value) return;
    await _store.write(_clientVariantKey, value.name);
    _clientVariant = value;
    update();
  }
}

T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

int? _readInt(Object? value) => value is int ? value : null;
