import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import '../core/window/desktop_window_service.dart';

/// Adds client-side resize hit targets around an undecorated Linux window.
///
/// Windows retains its native resize frame when NativeApi hides the caption,
/// so adding an inner Flutter hit target there would only steal content space.
final class WindowResizeFrame extends StatelessWidget {
  const WindowResizeFrame({
    required this.window,
    required this.child,
    this.edgeSize = 3,
    this.cornerSize = 8,
    super.key,
  });

  final DesktopWindowService window;
  final Widget child;
  final double edgeSize;
  final double cornerSize;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.linux) return child;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        Positioned(
          key: const ValueKey<String>('window-resize-top'),
          top: 0,
          left: cornerSize,
          right: cornerSize,
          height: edgeSize,
          child: _ResizeHandle(
            window: window,
            cursor: SystemMouseCursors.resizeUp,
          ),
        ),
        Positioned(
          key: const ValueKey<String>('window-resize-bottom'),
          bottom: 0,
          left: cornerSize,
          right: cornerSize,
          height: edgeSize,
          child: _ResizeHandle(
            window: window,
            cursor: SystemMouseCursors.resizeDown,
          ),
        ),
        Positioned(
          key: const ValueKey<String>('window-resize-left'),
          top: cornerSize,
          bottom: cornerSize,
          left: 0,
          width: edgeSize,
          child: _ResizeHandle(
            window: window,
            cursor: SystemMouseCursors.resizeLeft,
          ),
        ),
        Positioned(
          key: const ValueKey<String>('window-resize-right'),
          top: cornerSize,
          bottom: cornerSize,
          right: 0,
          width: edgeSize,
          child: _ResizeHandle(
            window: window,
            cursor: SystemMouseCursors.resizeRight,
          ),
        ),
        Positioned(
          key: const ValueKey<String>('window-resize-top-left'),
          top: 0,
          left: 0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            window: window,
            cursor: SystemMouseCursors.resizeUpLeft,
          ),
        ),
        Positioned(
          key: const ValueKey<String>('window-resize-top-right'),
          top: 0,
          right: 0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            window: window,
            cursor: SystemMouseCursors.resizeUpRight,
          ),
        ),
        Positioned(
          key: const ValueKey<String>('window-resize-bottom-left'),
          bottom: 0,
          left: 0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            window: window,
            cursor: SystemMouseCursors.resizeDownLeft,
          ),
        ),
        Positioned(
          key: const ValueKey<String>('window-resize-bottom-right'),
          bottom: 0,
          right: 0,
          width: cornerSize,
          height: cornerSize,
          child: _ResizeHandle(
            window: window,
            cursor: SystemMouseCursors.resizeDownRight,
          ),
        ),
      ],
    );
  }
}

final class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({required this.window, required this.cursor});

  final DesktopWindowService window;
  final MouseCursor cursor;

  void _startResize(PointerDownEvent event) {
    if ((event.buttons & kPrimaryMouseButton) == 0) return;
    // GTK must receive the request while the initiating button press is still
    // active, which is especially important for native Wayland resize grabs.
    unawaited(window.startResizing());
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: cursor,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _startResize,
      child: const SizedBox.expand(),
    ),
  );
}
