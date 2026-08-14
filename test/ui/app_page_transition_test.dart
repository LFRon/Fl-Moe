import 'package:fl_moe/features/navigation/app_navigation_controller.dart';
import 'package:fl_moe/ui/app_page_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('top-level sections use the page_transition fade effect', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(section: AppSection.home, label: 'home'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _testApp(section: AppSection.discover, label: 'discover'),
    );
    await tester.pump();

    expect(find.byType(AnimatedSwitcher), findsOneWidget);
    expect(_insideTransition(find.byType(FadeTransition)), findsNWidgets(2));
    expect(_insideTransition(find.byType(ScaleTransition)), findsNothing);
    expect(find.text('home'), findsOneWidget);
    expect(find.text('discover'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('home'), findsNothing);
    expect(find.text('discover'), findsOneWidget);
  });

  testWidgets(
    'collection detail uses page_transition shared-axis scale both ways',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _testApp(section: AppSection.discover, label: 'discover'),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _testApp(section: AppSection.collection, label: 'collection'),
      );
      await tester.pump();

      expect(_insideTransition(find.byType(ScaleTransition)), findsNWidgets(2));
      final entering = tester.widget<ScaleTransition>(
        find
            .ancestor(
              of: find.text('collection'),
              matching: find.byType(ScaleTransition),
            )
            .first,
      );
      expect(entering.scale.status, AnimationStatus.forward);

      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _testApp(section: AppSection.discover, label: 'discover again'),
      );
      await tester.pump();

      expect(_insideTransition(find.byType(ScaleTransition)), findsNWidgets(2));
      final leaving = tester.widget<ScaleTransition>(
        find
            .ancestor(
              of: find.text('collection'),
              matching: find.byType(ScaleTransition),
            )
            .first,
      );
      expect(leaving.scale.status, AnimationStatus.reverse);
    },
  );

  testWidgets('reduced motion switches pages immediately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        section: AppSection.home,
        label: 'home',
        disableAnimations: true,
      ),
    );

    await tester.pumpWidget(
      _testApp(
        section: AppSection.discover,
        label: 'discover',
        disableAnimations: true,
      ),
    );

    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(find.text('home'), findsNothing);
    expect(find.text('discover'), findsOneWidget);
  });

  testWidgets('rebuilding the same section does not start a transition', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(section: AppSection.home, label: 'first'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _testApp(section: AppSection.home, label: 'second'),
    );
    await tester.pump();

    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    expect(_insideTransition(find.byType(FadeTransition)), findsOneWidget);
  });

  testWidgets('rapid section changes keep only the latest page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(section: AppSection.home, label: 'home'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _testApp(section: AppSection.discover, label: 'discover'),
    );
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpWidget(
      _testApp(section: AppSection.settings, label: 'settings'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('settings'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('home'), findsNothing);
    expect(find.text('discover'), findsNothing);
    expect(find.text('settings'), findsOneWidget);
  });
}

Widget _testApp({
  required AppSection section,
  required String label,
  bool disableAnimations = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(
      body: FlMoePageTransition(
        section: section,
        child: Center(child: Text(label)),
      ),
    ),
  ),
);

Finder _insideTransition(Finder finder) =>
    find.descendant(of: find.byType(FlMoePageTransition), matching: finder);
