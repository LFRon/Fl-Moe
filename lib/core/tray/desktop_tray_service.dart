import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nativeapi/nativeapi.dart' as nativeapi;

import '../../features/player/playback_controller.dart';
import '../window/desktop_window_service.dart';

abstract interface class DesktopTrayService {
  bool get isAvailable;

  Future<void> initialize({
    required DesktopWindowService window,
    required PlaybackController playback,
  });

  Future<void> dispose();
}

final class NativeApiDesktopTrayService implements DesktopTrayService {
  nativeapi.TrayIcon? _tray;
  nativeapi.Image? _icon;
  nativeapi.Menu? _menu;
  nativeapi.MenuItem? _showHideItem;
  nativeapi.MenuItem? _previousItem;
  nativeapi.MenuItem? _playPauseItem;
  nativeapi.MenuItem? _nextItem;
  nativeapi.MenuItem? _quitItem;
  PlaybackController? _playback;
  bool _initialized = false;
  bool _available = false;
  String _lastDescription = '';

  @override
  bool get isAvailable => _available;

  bool get _isDesktop => Platform.isLinux || Platform.isWindows;

  @override
  Future<void> initialize({
    required DesktopWindowService window,
    required PlaybackController playback,
  }) async {
    if (_initialized) return;
    _initialized = true;
    if (!_isDesktop || !nativeapi.TrayManager.instance.isSupported) return;

    try {
      final tray = nativeapi.TrayIcon();
      _tray = tray;
      final icon = nativeapi.Image.fromAsset('assets/images/app_mascot.png');
      if (icon == null) {
        throw StateError('无法读取 Fl-Moe 托盘图标资源');
      }
      _icon = icon;
      final menu = nativeapi.Menu();
      _menu = menu;
      final showHideItem = nativeapi.MenuItem('显示 / 隐藏主窗口');
      _showHideItem = showHideItem;
      final previousItem = nativeapi.MenuItem('上一首');
      _previousItem = previousItem;
      final playPauseItem = nativeapi.MenuItem('播放 / 暂停');
      _playPauseItem = playPauseItem;
      final nextItem = nativeapi.MenuItem('下一首');
      _nextItem = nextItem;
      final quitItem = nativeapi.MenuItem('退出 Fl-Moe');
      _quitItem = quitItem;

      menu
        ..addItem(showHideItem)
        ..addSeparator()
        ..addItem(previousItem)
        ..addItem(playPauseItem)
        ..addItem(nextItem)
        ..addSeparator()
        ..addItem(quitItem);

      showHideItem.addCallbackListener<nativeapi.MenuItemClickedEvent>((_) {
        unawaited(window.toggleVisibility());
      });
      previousItem.addCallbackListener<nativeapi.MenuItemClickedEvent>((_) {
        unawaited(playback.previous());
      });
      playPauseItem.addCallbackListener<nativeapi.MenuItemClickedEvent>((_) {
        unawaited(playback.toggle());
      });
      nextItem.addCallbackListener<nativeapi.MenuItemClickedEvent>((_) {
        unawaited(playback.next());
      });
      quitItem.addCallbackListener<nativeapi.MenuItemClickedEvent>((_) {
        unawaited(window.close());
      });
      tray
        ..addCallbackListener<nativeapi.TrayIconClickedEvent>((_) {
          unawaited(window.toggleVisibility());
        })
        ..addCallbackListener<nativeapi.TrayIconDoubleClickedEvent>((_) {
          unawaited(window.show());
        });

      _playback = playback;
      playback.addListener(_syncPlaybackState);

      tray
        ..icon = icon
        ..title = 'Fl-Moe'
        ..tooltip = 'Fl-Moe'
        ..contextMenu = menu
        ..contextMenuTrigger = nativeapi.ContextMenuTrigger.rightClicked
        ..isVisible = true;
      _available = true;
      _syncPlaybackState();
    } on Object catch (error) {
      debugPrint('Fl-Moe tray initialization failed: $error');
      await _disposeNativeObjects();
    }
  }

  void _syncPlaybackState() {
    final playback = _playback;
    final tray = _tray;
    if (playback == null || tray == null) return;
    final track = playback.currentTrack;
    final description = track == null
        ? 'Fl-Moe'
        : '${track.title} - ${track.artist}';
    if (_lastDescription != description) {
      _lastDescription = description;
      tray
        ..title = description
        ..tooltip = description;
    }
  }

  @override
  Future<void> dispose() async {
    _initialized = true;
    await _disposeNativeObjects();
  }

  Future<void> _disposeNativeObjects() async {
    _available = false;
    final playback = _playback;
    if (playback != null) playback.removeListener(_syncPlaybackState);
    _playback = null;
    _lastDescription = '';
    final tray = _tray;
    _tray = null;
    if (tray != null) {
      tray.isVisible = false;
      tray.dispose();
    }
    _showHideItem?.dispose();
    _previousItem?.dispose();
    _playPauseItem?.dispose();
    _nextItem?.dispose();
    _quitItem?.dispose();
    _showHideItem = null;
    _previousItem = null;
    _playPauseItem = null;
    _nextItem = null;
    _quitItem = null;
    _menu?.dispose();
    _menu = null;
    _icon?.dispose();
    _icon = null;
  }
}

final class NoopDesktopTrayService implements DesktopTrayService {
  const NoopDesktopTrayService();

  @override
  bool get isAvailable => false;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize({
    required DesktopWindowService window,
    required PlaybackController playback,
  }) async {}
}
