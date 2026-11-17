import 'package:fl_moe/app/app_theme.dart';
import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/core/tray/desktop_tray_service.dart';
import 'package:fl_moe/core/window/desktop_window_service.dart';
import 'package:fl_moe/features/auth/authentication_controller.dart';
import 'package:fl_moe/features/auth/kugou_user_profile.dart';
import 'package:fl_moe/features/navigation/app_navigation_controller.dart';
import 'package:fl_moe/features/player/audio_engine.dart';
import 'package:fl_moe/features/player/playback_controller.dart';
import 'package:fl_moe/features/settings/app_settings_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/player_bar.dart';
import 'package:fl_moe/ui/widgets/loading_skeletons.dart';
import 'package:fl_moe/ui/widgets/network_artwork.dart';
import 'package:fl_moe/ui/window_resize_frame.dart';
import 'package:fl_moe/ui/window_title_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:skeleton_shimmer/skeleton_shimmer.dart';

void main() {
  testWidgets('Fl-Moe theme renders a Material surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: const Scaffold(body: Text('Fl-Moe')),
      ),
    );

    expect(find.text('Fl-Moe'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  test('interactive component themes use a desktop click cursor', () {
    final theme = FlMoeTheme.light(const Color(0xFF4C9BE8));
    final cursorProperties = <WidgetStateProperty<MouseCursor?>?>[
      theme.textButtonTheme.style?.mouseCursor,
      theme.filledButtonTheme.style?.mouseCursor,
      theme.outlinedButtonTheme.style?.mouseCursor,
      theme.elevatedButtonTheme.style?.mouseCursor,
      theme.iconButtonTheme.style?.mouseCursor,
      theme.segmentedButtonTheme.style?.mouseCursor,
      theme.listTileTheme.mouseCursor,
      theme.popupMenuTheme.mouseCursor,
    ];

    for (final cursorProperty in cursorProperties) {
      expect(cursorProperty, isNotNull);
      expect(
        cursorProperty!.resolve(const <WidgetState>{}),
        SystemMouseCursors.click,
      );
      expect(
        cursorProperty.resolve(const <WidgetState>{WidgetState.disabled}),
        SystemMouseCursors.basic,
      );
    }
  });

  testWidgets('window controls are minimize, maximize, then close', (
    tester,
  ) async {
    final window = _RecordingWindowService();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlMoeWindowControls(window: window)),
      ),
    );

    final minimize = tester.getCenter(find.byTooltip('最小化')).dx;
    final maximize = tester.getCenter(find.byTooltip('最大化 / 还原')).dx;
    final close = tester.getCenter(find.byTooltip('关闭')).dx;
    expect(minimize, lessThan(maximize));
    expect(maximize, lessThan(close));

    await tester.tap(find.byTooltip('最小化'));
    await tester.tap(find.byTooltip('最大化 / 还原'));
    await tester.tap(find.byTooltip('关闭'));
    expect(window.actions, <String>['minimize', 'maximize', 'close']);
  });

  testWidgets('logged-in account button uses a circular hover target', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(1200, 200));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      Get.reset();
    });
    const backend = _IdleMusicBackend(loggedIn: true);
    final profileRepository = KugouUserProfileRepository(MemoryKeyValueStore());
    await profileRepository.save(
      const KugouUserProfile(
        userId: '123456',
        nickname: '测试用户',
        avatarUrl: 'https://img.example.test/avatar.jpg',
      ),
      variant: KugouClientVariant.lite,
    );
    Get.put<AppSettingsController>(
      AppSettingsController.load(MemoryKeyValueStore()),
    );
    Get.put<AuthenticationController>(
      AuthenticationController(backend, profileRepository: profileRepository),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: Scaffold(
          body: FlMoeTitleBar(
            window: _RecordingWindowService(),
            tray: const NoopDesktopTrayService(),
          ),
        ),
      ),
    );

    final accountButton = find.byKey(
      const ValueKey<String>('kugou-account-button'),
    );
    expect(tester.getSize(accountButton), const Size.square(40));
    final popup = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>),
    );
    expect(popup.borderRadius, BorderRadius.circular(20));
    expect(popup.splashRadius, 20);
    final avatar = tester.widget<NetworkArtwork>(
      find.byKey(const ValueKey<String>('kugou-account-avatar')),
    );
    expect(avatar.url, 'https://img.example.test/avatar.jpg');
    expect(avatar.size, 30);
    expect(avatar.borderRadius, 15);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('close button always hides the window when tray is available', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(Get.reset);
    const backend = _IdleMusicBackend();
    Get.put<AppSettingsController>(
      AppSettingsController.load(MemoryKeyValueStore()),
    );
    Get.put<AuthenticationController>(AuthenticationController(backend));
    final window = _RecordingWindowService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlMoeTitleBar(
            window: window,
            tray: const _AvailableTrayService(),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    expect(window.actions, <String>['hide']);
  });

  testWidgets('close button closes safely when tray is unavailable', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(Get.reset);
    const backend = _IdleMusicBackend();
    Get.put<AppSettingsController>(
      AppSettingsController.load(MemoryKeyValueStore()),
    );
    Get.put<AuthenticationController>(AuthenticationController(backend));
    final window = _RecordingWindowService();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlMoeTitleBar(
            window: window,
            tray: const NoopDesktopTrayService(),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    expect(window.actions, <String>['close']);
  });

  testWidgets('player trailing controls use compact optical spacing', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(1200, 600));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      Get.reset();
    });
    final player = PlaybackController(
      const _IdleMusicBackend(),
      NoopAudioEngine(),
      MemoryKeyValueStore(),
    );
    Get.put<PlaybackController>(player);

    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: const Scaffold(
          body: Column(children: <Widget>[Spacer(), PlayerBar()]),
        ),
      ),
    );

    final desktopButtonCenter = tester.getCenter(find.byTooltip('桌面歌词（暂未实现）'));
    final desktopIconCenter = tester.getCenter(
      find.byIcon(Icons.lyrics_outlined),
    );
    final statusButtonCenter = tester.getCenter(find.byTooltip('状态栏歌词（暂未实现）'));
    final statusIconCenter = tester.getCenter(
      find.byIcon(Icons.subtitles_outlined),
    );
    expect(desktopIconCenter.dx, closeTo(desktopButtonCenter.dx - 1, 0.01));
    expect(statusIconCenter.dx, closeTo(statusButtonCenter.dx, 0.01));

    final volumeSlider = find.byKey(
      const ValueKey<String>('player-volume-slider'),
    );
    final volumeSliderTheme = SliderTheme.of(tester.element(volumeSlider));
    final overlayShape = volumeSliderTheme.overlayShape;
    expect(overlayShape, isA<RoundSliderOverlayShape>());
    expect((overlayShape! as RoundSliderOverlayShape).overlayRadius, 12);

    await tester.tap(find.byTooltip('播放模式：列表循环'));
    await tester.pumpAndSettle();
    expect(find.text('随机播放'), findsOneWidget);
    expect(find.text('列表循环'), findsOneWidget);
    expect(find.text('单曲循环'), findsOneWidget);
    expect(find.text('顺序播放'), findsOneWidget);

    await tester.tap(find.text('单曲循环'));
    await tester.pumpAndSettle();
    expect(player.playbackMode, PlaybackMode.singleLoop);
    expect(find.byTooltip('播放模式：单曲循环'), findsOneWidget);
  });

  testWidgets('player bar has no visible or editable playback queue', (
    tester,
  ) async {
    Get.testMode = true;
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
      Get.reset();
    });
    Get.put<PlaybackController>(
      PlaybackController(
        const _IdleMusicBackend(),
        NoopAudioEngine(),
        MemoryKeyValueStore(),
      ),
    );
    Get.put<AppNavigationController>(AppNavigationController());

    await tester.pumpWidget(
      MaterialApp(
        theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
        home: const Scaffold(body: PlayerBar()),
      ),
    );

    expect(find.byTooltip('播放队列'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('clear-playback-queue')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('playback-queue-count')),
      findsNothing,
    );
  });

  testWidgets('Linux drag starts on pointer down while a skeleton animates', (
    tester,
  ) async {
    Get.testMode = true;
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      const backend = _IdleMusicBackend();
      final window = _RecordingWindowService();
      addTearDown(Get.reset);
      Get.put<AppSettingsController>(
        AppSettingsController.load(MemoryKeyValueStore()),
      );
      Get.put<AuthenticationController>(AuthenticationController(backend));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                FlMoeTitleBar(window: window, tray: NoopDesktopTrayService()),
                const Expanded(
                  child: FlMoeSkeletonScope(
                    child: Center(
                      child: FlMoeSkeletonBox(width: 240, height: 80),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final dragRegion = find.byKey(
        const ValueKey<String>('window-drag-region'),
      );
      final gesture = await tester.startGesture(tester.getCenter(dragRegion));
      expect(window.actions, <String>['drag']);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));

      window.actions.clear();
      await tester.tap(dragRegion);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(dragRegion);
      await tester.pump(const Duration(milliseconds: 50));
      expect(window.actions, <String>['drag', 'drag', 'maximize']);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpWidget(const SizedBox.shrink());
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Linux frameless window exposes resize edges and corners', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      final window = _RecordingWindowService();
      await tester.pumpWidget(
        MaterialApp(
          home: WindowResizeFrame(
            window: window,
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      );

      expect(find.byKey(const ValueKey<String>('window-resize-top')), findsOne);
      expect(
        find.byKey(const ValueKey<String>('window-resize-bottom-right')),
        findsOne,
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey<String>('window-resize-top')))
            .height,
        3,
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey<String>('window-resize-bottom-right')),
        ),
        const Size.square(8),
      );
      final cornerRegion = tester.widget<MouseRegion>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('window-resize-bottom-right')),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(cornerRegion.cursor, SystemMouseCursors.resizeDownRight);

      final gesture = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey<String>('window-resize-bottom-right')),
        ),
      );
      expect(window.actions, <String>['resize']);
      await gesture.up();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a skeleton scope uses one shimmer layer for all bones', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FlMoeSkeletonScope(
          child: Column(
            children: <Widget>[
              FlMoeSkeletonBox(width: 100, height: 20),
              FlMoeSkeletonLine(width: 80),
              FlMoeSkeletonCircle(size: 30),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Shimmer), findsOneWidget);
    expect(find.byType(ShimmerScope), findsNothing);
  });
}

final class _IdleMusicBackend implements MusicBackend {
  const _IdleMusicBackend({this.loggedIn = false});

  final bool loggedIn;

  @override
  KugouClientVariant get clientVariant => KugouClientVariant.lite;

  @override
  BackendSessionState get sessionState => loggedIn
      ? const BackendSessionState(
          isLoggedIn: true,
          userId: '123456',
          hasRegisteredDevice: true,
        )
      : const BackendSessionState(
          isLoggedIn: false,
          userId: '0',
          hasRegisteredDevice: false,
        );

  @override
  Future<KugouResponse<KugouJsonObject>> callJson(
    String route, {
    KugouJsonObject parameters = const <String, Object?>{},
  }) => throw UnsupportedError('No network calls are expected in this test.');

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

final class _RecordingWindowService implements DesktopWindowService {
  final List<String> actions = <String>[];

  @override
  bool get isVisible => true;

  @override
  Future<void> close() async => actions.add('close');

  @override
  Future<void> initialize() async {}

  @override
  Future<void> hide() async => actions.add('hide');

  @override
  Future<void> minimize() async => actions.add('minimize');

  @override
  Future<void> show() async => actions.add('show');

  @override
  Future<void> startDragging() async => actions.add('drag');

  @override
  Future<void> startResizing() async => actions.add('resize');

  @override
  Future<void> toggleMaximize() async => actions.add('maximize');

  @override
  Future<void> toggleVisibility() async => actions.add('toggle-visibility');
}

final class _AvailableTrayService implements DesktopTrayService {
  const _AvailableTrayService();

  @override
  bool get isAvailable => true;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize({
    required DesktopWindowService window,
    required PlaybackController playback,
  }) async {}
}
