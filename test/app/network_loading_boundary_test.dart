import 'dart:async';

import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/features/auth/authentication_controller.dart';
import 'package:fl_moe/features/music/music_catalog_controller.dart';
import 'package:fl_moe/features/navigation/app_navigation_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/pages/discover_page/discover_page.dart';
import 'package:fl_moe/ui/pages/home_page/home_page.dart';
import 'package:fl_moe/ui/pages/home_page/widgets/catalog_skeleton.dart';
import 'package:fl_moe/ui/pages/home_page/widgets/home_hero.dart';
import 'package:fl_moe/ui/pages/search_page/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  test('caches discover data until the user explicitly refreshes it', () async {
    final backend = _PendingMusicBackend(completeRequests: true);
    final catalog = MusicCatalogController(backend);

    await catalog.loadDiscoverCatalog();
    expect(backend.callCount, 2);

    await catalog.loadDiscoverCatalog();
    expect(backend.callCount, 2);

    await catalog.refreshDiscoverCatalog();
    expect(backend.callCount, 4);
  });

  testWidgets('keeps local home UI visible while network data is pending', (
    tester,
  ) async {
    Get.testMode = true;
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });
    final backend = _PendingMusicBackend();
    final catalog = MusicCatalogController(backend);
    Get.put<AuthenticationController>(AuthenticationController(backend));
    Get.put<MusicCatalogController>(catalog);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HomePage())),
    );

    expect(find.byType(HomeHero), findsOneWidget);
    expect(find.text('欢迎来到 Fl-Moe'), findsOneWidget);
    expect(find.text('大家都在搜'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('hot-words-skeleton')),
      findsOneWidget,
    );
    expect(find.byType(CatalogSkeleton), findsOneWidget);
    expect(backend.callCount, 0);

    unawaited(catalog.loadHomeCatalog());
    await tester.pump();
    expect(backend.callCount, 2);
    expect(
      backend.routes,
      containsAll(<String>['/search/hot', '/top/playlist']),
    );
    expect(backend.routes, isNot(contains('/rank/list')));
    expect(find.byType(HomeHero), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('loads discover endpoints only after discover is opened', (
    tester,
  ) async {
    Get.testMode = true;
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });
    final backend = _PendingMusicBackend();
    final catalog = MusicCatalogController(backend);
    Get.put<MusicCatalogController>(catalog);

    unawaited(catalog.loadHomeCatalog());
    expect(backend.routes, isNot(contains('/rank/list')));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DiscoverPage())),
    );

    expect(
      backend.routes.where((route) => route == '/rank/list'),
      hasLength(1),
    );
    expect(backend.callCount, 4);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('keeps search controls visible while suggestions are pending', (
    tester,
  ) async {
    Get.testMode = true;
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      Get.reset();
    });
    final backend = _PendingMusicBackend();
    Get.put<AppNavigationController>(AppNavigationController());
    Get.put<MusicSearchController>(MusicSearchController(backend));
    Get.put<MusicCatalogController>(MusicCatalogController(backend));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SearchPage())),
    );

    expect(find.text('搜索'), findsWidgets);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('search-suggestions-skeleton')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final class _PendingMusicBackend implements MusicBackend {
  _PendingMusicBackend({this.completeRequests = false});

  final bool completeRequests;
  int callCount = 0;
  final List<String> routes = <String>[];

  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => const BackendSessionState(
    isLoggedIn: false,
    userId: '0',
    hasRegisteredDevice: false,
  );

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) {
    callCount += 1;
    routes.add(route);
    if (completeRequests) {
      return Future<KugouResponse<KugouJsonObject>>.value(
        const KugouResponse<KugouJsonObject>(
          status: 200,
          httpStatus: 200,
          body: <String, Object?>{},
        ),
      );
    }
    return Completer<KugouResponse<KugouJsonObject>>().future;
  }

  @override
  Future<void> clearAuthentication() async {}

  @override
  Future<void> close() async {}

  @override
  Future<bool> ensureDeviceRegistered() async => false;

  @override
  Future<void> flushSession() async {}

  @override
  Future<void> setClientVariant(KugouClientVariant variant) async {}
}
