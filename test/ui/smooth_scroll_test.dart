import 'package:fl_moe/ui/scrolling/fl_moe_smooth_scroll.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silky_scroll/silky_scroll.dart';

void main() {
  setUp(SilkyScrollGlobalManager.instance.resetForTesting);
  tearDown(SilkyScrollGlobalManager.instance.resetForTesting);

  test('Fl-Moe shares one responsive smooth-scroll configuration', () {
    expect(
      flMoeSmoothScrollConfig.silkyScrollDuration,
      greaterThan(Duration.zero),
    );
    expect(flMoeSmoothScrollConfig.scrollSpeed, greaterThan(0));
  });

  testWidgets('mouse-wheel deltas merge into one smooth animation', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 300,
          child: SilkyListView.builder(
            key: const ValueKey<String>('smooth-list'),
            silkyConfig: flMoeSmoothScrollConfig,
            controller: controller,
            itemCount: 40,
            itemBuilder: (context, index) =>
                SizedBox(height: 80, child: Text('Item $index')),
          ),
        ),
      ),
    );

    final position = tester.getCenter(
      find.byKey(const ValueKey<String>('smooth-list')),
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: position,
        kind: PointerDeviceKind.mouse,
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    final oneStepTarget = 120 * flMoeSmoothScrollConfig.scrollSpeed;
    final finalTarget = oneStepTarget * 2;
    final firstFrameOffset = controller.offset;
    expect(firstFrameOffset, greaterThan(0));
    expect(firstFrameOffset, lessThan(oneStepTarget));

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: position,
        kind: PointerDeviceKind.mouse,
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.offset, greaterThan(firstFrameOffset));
    expect(controller.offset, lessThan(finalTarget));

    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(finalTarget, 0.01));
  });

  testWidgets('trackpad scrolling keeps Flutter native direct response', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          height: 300,
          child: SilkyListView.builder(
            key: const ValueKey<String>('trackpad-list'),
            silkyConfig: flMoeSmoothScrollConfig,
            controller: controller,
            itemCount: 40,
            itemBuilder: (context, index) =>
                SizedBox(height: 80, child: Text('Item $index')),
          ),
        ),
      ),
    );

    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: tester.getCenter(
          find.byKey(const ValueKey<String>('trackpad-list')),
        ),
        kind: PointerDeviceKind.trackpad,
        scrollDelta: const Offset(0, 60),
      ),
    );
    await tester.pump();

    expect(controller.offset, closeTo(60, 0.01));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset, closeTo(60, 0.01));
  });
}
