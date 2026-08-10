import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

abstract interface class DesktopWindowService {
  Future<void> initialize();

  Future<void> startDragging();

  Future<void> minimize();

  Future<void> toggleMaximize();

  Future<void> close();
}

final class WindowManagerDesktopWindowService implements DesktopWindowService {
  const WindowManagerDesktopWindowService();

  bool get _isDesktop => Platform.isLinux || Platform.isWindows;

  @override
  Future<void> initialize() async {
    if (!_isDesktop) return;
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(1280, 800),
      minimumSize: Size(960, 640),
      center: true,
      title: 'Fl-Moe',
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  @override
  Future<void> startDragging() async {
    if (_isDesktop) await windowManager.startDragging();
  }

  @override
  Future<void> minimize() async {
    if (_isDesktop) await windowManager.minimize();
  }

  @override
  Future<void> toggleMaximize() async {
    if (!_isDesktop) return;
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  @override
  Future<void> close() async {
    if (_isDesktop) await windowManager.close();
  }
}

final class NoopDesktopWindowService implements DesktopWindowService {
  const NoopDesktopWindowService();

  @override
  Future<void> close() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> minimize() async {}

  @override
  Future<void> startDragging() async {}

  @override
  Future<void> toggleMaximize() async {}
}
