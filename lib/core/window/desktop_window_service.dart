import 'dart:io';

import 'package:nativeapi/nativeapi.dart' as nativeapi;

abstract interface class DesktopWindowService {
  Future<void> initialize();

  Future<void> startDragging();

  Future<void> minimize();

  Future<void> toggleMaximize();

  Future<void> close();
}

final class NativeApiDesktopWindowService implements DesktopWindowService {
  nativeapi.Window? _mainWindow;

  bool get _isDesktop => Platform.isLinux || Platform.isWindows;

  @override
  Future<void> initialize() async {
    if (!_isDesktop) return;
    final window = nativeapi.WindowManager.instance.getMain();
    if (window == null) {
      throw StateError('NativeAPI could not find the Flutter main window.');
    }
    _mainWindow = window;
    window.title = 'Fl-Moe';
    window.titleBarStyle = nativeapi.TitleBarStyle.hidden;
    window.setSize(1280, 800);
    window.setMinimumSize(960, 640);
    window.center();
  }

  @override
  Future<void> startDragging() async {
    _mainWindow?.startDragging();
  }

  @override
  Future<void> minimize() async {
    _mainWindow?.minimize();
  }

  @override
  Future<void> toggleMaximize() async {
    final window = _mainWindow;
    if (window == null) return;
    if (window.isMaximized) {
      window.unmaximize();
    } else {
      window.maximize();
    }
  }

  @override
  Future<void> close() async {
    _mainWindow?.close();
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
