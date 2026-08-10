import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/backend/music_backend.dart';
import '../../../core/storage/app_directories.dart';
import '../../../features/auth/authentication_controller.dart';
import '../../../features/music/music_catalog_controller.dart';
import '../../../features/settings/app_settings_controller.dart';
import '../../../kugou_api.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/about_card.dart';
import 'widgets/color_choice.dart';
import 'widgets/path_row.dart';
import 'widgets/setting_row.dart';
import 'widgets/settings_section.dart';

final class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.directories, super.key});

  final AppDirectories directories;

  Future<void> _setClientVariant(
    BuildContext context,
    KugouClientVariant variant,
  ) async {
    final backend = Get.find<MusicBackend>();
    final settings = Get.find<AppSettingsController>();
    final authentication = Get.find<AuthenticationController>();
    final catalog = Get.find<MusicCatalogController>();
    try {
      final wasLoggedIn = backend.sessionState.isLoggedIn;
      await backend.setClientVariant(variant);
      settings.setClientVariant(variant);
      authentication.refreshSessionState();
      unawaited(catalog.refreshLoadedCatalogs());
      if (!context.mounted) return;
      final label = variant == KugouClientVariant.lite ? '概念版' : '标准版';
      final isLoggedIn = backend.sessionState.isLoggedIn;
      final message = switch ((wasLoggedIn, isLoggedIn)) {
        (true, false) => '酷狗音源已切换为$label；该客户端需要单独登录',
        (false, true) => '酷狗音源已切换为$label，并已恢复该客户端登录',
        _ => '酷狗音源已切换为$label',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('音源切换失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AppSettingsController>(
    builder: (settings) => ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
      children: <Widget>[
        const PageHeading(
          title: '设置',
          subtitle: '外观、窗口和数据目录会立即保存到 Fl-Moe 专属空间',
        ),
        const SizedBox(height: 24),
        SettingsSection(
          title: '外观',
          icon: Icons.palette_outlined,
          children: <Widget>[
            SettingRow(
              title: '主题模式',
              subtitle: '跟随系统，或固定为浅色 / 深色',
              control: SegmentedButton<AppThemePreference>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<AppThemePreference>>[
                  ButtonSegment<AppThemePreference>(
                    value: AppThemePreference.system,
                    icon: Icon(Icons.brightness_auto_rounded),
                    label: Text('系统'),
                  ),
                  ButtonSegment<AppThemePreference>(
                    value: AppThemePreference.light,
                    icon: Icon(Icons.light_mode_rounded),
                    label: Text('浅色'),
                  ),
                  ButtonSegment<AppThemePreference>(
                    value: AppThemePreference.dark,
                    icon: Icon(Icons.dark_mode_rounded),
                    label: Text('深色'),
                  ),
                ],
                selected: <AppThemePreference>{settings.themePreference},
                onSelectionChanged: (selection) =>
                    settings.setThemePreference(selection.single),
              ),
            ),
            const Divider(height: 1),
            SettingRow(
              title: '强调色',
              subtitle: '界面控件和播放状态使用的主色',
              control: Wrap(
                spacing: 9,
                children:
                    const <Color>[
                          Color(0xFF4C9BE8),
                          Color(0xFF8C74E8),
                          Color(0xFFEC6F9B),
                          Color(0xFF38A889),
                          Color(0xFFF09A42),
                        ]
                        .map(
                          (color) => ColorChoice(
                            color: color,
                            selected: settings.accentColor == color,
                            onSelected: () => settings.setAccentColor(color),
                          ),
                        )
                        .toList(growable: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsSection(
          title: '酷狗服务',
          icon: Icons.library_music_outlined,
          children: <Widget>[
            SettingRow(
              title: '音源客户端',
              subtitle: '默认使用概念版；两种客户端的登录凭据分别保存，首次切换需要单独登录',
              control: SegmentedButton<KugouClientVariant>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<KugouClientVariant>>[
                  ButtonSegment<KugouClientVariant>(
                    value: KugouClientVariant.lite,
                    label: Text('概念版'),
                  ),
                  ButtonSegment<KugouClientVariant>(
                    value: KugouClientVariant.standard,
                    label: Text('标准版'),
                  ),
                ],
                selected: <KugouClientVariant>{settings.clientVariant},
                onSelectionChanged: (selection) =>
                    unawaited(_setClientVariant(context, selection.single)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsSection(
          title: '桌面窗口',
          icon: Icons.desktop_windows_outlined,
          children: <Widget>[
            SettingRow(
              title: '窗口控制键位置',
              subtitle: '最小化、最大化、关闭控制键可以放在标题栏左侧或右侧',
              control: SegmentedButton<WindowControlSide>(
                showSelectedIcon: false,
                segments: const <ButtonSegment<WindowControlSide>>[
                  ButtonSegment<WindowControlSide>(
                    value: WindowControlSide.left,
                    label: Text('左侧'),
                  ),
                  ButtonSegment<WindowControlSide>(
                    value: WindowControlSide.right,
                    label: Text('右侧'),
                  ),
                ],
                selected: <WindowControlSide>{settings.windowControlSide},
                onSelectionChanged: (selection) =>
                    settings.setWindowControlSide(selection.single),
              ),
            ),
            const Divider(height: 1),
            const SettingRow(
              title: '关闭到系统托盘',
              subtitle: '已预留窗口服务接口；nativeapi 稳定后再启用，避免当前 WIP API 影响 Wayland 主线',
              control: Switch(value: false, onChanged: null),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsSection(
          title: '歌词',
          icon: Icons.lyrics_outlined,
          children: <Widget>[
            SettingRow(
              title: '桌面歌词',
              subtitle: '本阶段仅保留入口，不绑定 Treeland 私有协议',
              control: OutlinedButton.icon(
                onPressed: () => showReservedFeature(context, '桌面歌词'),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('打开'),
              ),
            ),
            const Divider(height: 1),
            SettingRow(
              title: '状态栏歌词',
              subtitle: '本阶段仅保留入口，后续单独评估桌面协议能力',
              control: OutlinedButton.icon(
                onPressed: () => showReservedFeature(context, '状态栏歌词'),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('打开'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SettingsSection(
          title: '数据与缓存',
          icon: Icons.storage_rounded,
          children: <Widget>[
            PathRow(label: '配置目录', path: directories.config),
            const Divider(height: 1),
            PathRow(label: '数据目录', path: directories.data),
            const Divider(height: 1),
            PathRow(label: '缓存目录', path: directories.cache),
          ],
        ),
        const SizedBox(height: 18),
        const AboutCard(),
      ],
    ),
  );
}
