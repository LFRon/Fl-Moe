import 'package:fl_moe/app/app_theme.dart';
import 'package:fl_moe/core/backend/music_backend.dart';
import 'package:fl_moe/core/storage/app_directories.dart';
import 'package:fl_moe/core/storage/key_value_store.dart';
import 'package:fl_moe/features/settings/app_settings_controller.dart';
import 'package:fl_moe/kugou_api.dart';
import 'package:fl_moe/ui/pages/settings_page/settings_page.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets(
    'client popup requires confirmation and only saves the restart setting',
    (tester) async {
      Get.testMode = true;
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        Get.reset();
      });

      final store = MemoryKeyValueStore();
      final settings = AppSettingsController.load(store);
      Get.put<AppSettingsController>(settings);
      final directories = AppDirectories.fromEnvironment(
        operatingSystem: 'linux',
        environment: const <String, String>{'HOME': '/tmp/fl-moe-test'},
        separator: '/',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: FlMoeTheme.light(const Color(0xFF4C9BE8)),
          home: Scaffold(body: SettingsPage(directories: directories)),
        ),
      );

      expect(find.byType(SegmentedButton<KugouClientVariant>), findsNothing);
      expect(find.text('关闭到系统托盘'), findsNothing);
      expect(find.byType(Switch), findsNothing);
      expect(Get.isRegistered<MusicBackend>(), isFalse);
      final popup = tester.widget<PopupMenuButton<KugouClientVariant>>(
        find.byKey(const ValueKey<String>('kugou-client-variant-popup')),
      );
      expect(popup.borderRadius, BorderRadius.circular(20));
      expect(popup.splashRadius, 20);
      expect(
        popup.popUpAnimationStyle?.duration,
        const Duration(milliseconds: 300),
      );
      final qualityButton = find.byKey(
        const ValueKey<String>('maximum-playback-quality-button'),
      );
      final qualityArrow = find.descendant(
        of: qualityButton,
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      );
      expect(tester.getSize(qualityButton).width, greaterThanOrEqualTo(174));
      expect(qualityArrow, findsOneWidget);
      expect(
        tester.getTopRight(qualityButton).dx -
            tester.getTopRight(qualityArrow).dx,
        closeTo(11, 0.01),
        reason: 'the quality arrow should use the pill padding and border',
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('maximum-playback-quality-popup')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('playback-quality-master')),
      );
      await tester.pumpAndSettle();
      expect(settings.maximumPlaybackQuality, KugouPlaybackQuality.master);
      expect(
        AppSettingsController.load(store).maximumPlaybackQuality,
        KugouPlaybackQuality.master,
      );

      await _chooseStandardClient(tester);

      expect(find.text('切换音源客户端？'), findsOneWidget);
      expect(find.textContaining('需要重启应用后才会生效'), findsOneWidget);
      expect(settings.clientVariant, KugouClientVariant.lite);
      await tester.tap(
        find.byKey(const ValueKey<String>('cancel-client-variant-switch')),
      );
      await tester.pumpAndSettle();

      expect(settings.clientVariant, KugouClientVariant.lite);
      expect(
        AppSettingsController.load(store).clientVariant,
        KugouClientVariant.lite,
      );

      await _chooseStandardClient(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('confirm-client-variant-switch')),
      );
      await tester.pumpAndSettle();

      expect(settings.clientVariant, KugouClientVariant.standard);
      expect(
        AppSettingsController.load(store).clientVariant,
        KugouClientVariant.standard,
      );
      expect(find.text('已保存为标准版音源；请重启 Fl-Moe 后生效'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _chooseStandardClient(WidgetTester tester) async {
  await tester.tap(
    find.byKey(const ValueKey<String>('kugou-client-variant-button')),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const ValueKey<String>('kugou-client-variant-option-standard')),
  );
  await tester.pumpAndSettle();
}
