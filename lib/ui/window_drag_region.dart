import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../core/window/desktop_window_service.dart';

/// A reusable drag region for Fl-Moe's undecorated desktop window.
final class FlMoeWindowDragRegion extends StatelessWidget {
  const FlMoeWindowDragRegion({required this.window, this.width, super.key});

  final DesktopWindowService window;
  final double? width;

  void _startDragging() => unawaited(window.startDragging());

  @override
  Widget build(BuildContext context) {
    // GTK's move-drag request should be made while the initiating button
    // press is still current. Waiting for pan recognition is noticeably less
    // reliable on Wayland when the UI is painting an animated loading state.
    // Windows keeps pan-start activation so a click/double-click does not
    // enter its synchronous native move loop.
    final dragOnPointerDown = defaultTargetPlatform == TargetPlatform.linux;
    return SizedBox(
      width: width,
      height: double.infinity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: dragOnPointerDown ? (details) => _startDragging() : null,
        onPanStart: dragOnPointerDown ? null : (details) => _startDragging(),
        onDoubleTap: () => unawaited(window.toggleMaximize()),
      ),
    );
  }
}
