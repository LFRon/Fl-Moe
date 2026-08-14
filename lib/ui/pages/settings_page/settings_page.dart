import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/storage/app_directories.dart';
import '../../../features/settings/app_settings_controller.dart';
import '../../../kugou_api.dart';
import '../../scrolling/fl_moe_smooth_scroll.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/about_card.dart';
import 'widgets/client_variant_popup.dart';
import 'widgets/color_choice.dart';
import 'widgets/path_row.dart';
import 'widgets/playback_quality_popup.dart';
import 'widgets/setting_row.dart';
import 'widgets/settings_section.dart';

final class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.directories, super.key});

  final AppDirectories directories;

  Future<void> _setClientVariant(
    BuildContext context,
    AppSettingsController settings,
    KugouClientVariant variant,
  ) async {
    if (variant == settings.clientVariant) return;
    final currentLabel = kugouClientVariantLabel(settings.clientVariant);
    final nextLabel = kugouClientVariantLabel(variant);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.restart_alt_rounded),
        title: const Text('切换音源客户端？'),
        content: Text(
          '确定将下次启动使用的音源从$currentLabel更改为$nextLabel吗？\n\n'
          '这次更改只会保存到 Fl-Moe 配置数据库，不会切换当前正在运行的'
          '音源、登录会话或当前播放内容。需要重启应用后才会生效。',
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('cancel-client-variant-switch'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey<String>('confirm-client-variant-switch'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('是，保存设置'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await settings.setClientVariant(variant);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('已保存为$nextLabel音源；请重启 Fl-Moe 后生效')),
        );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('音源切换失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AppSettingsController>(
    builder: (settings) => SilkyListView(
      silkyConfig: flMoeSmoothScrollConfig,
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
              subtitle: '只保存下次启动使用的客户端，不会改变当前会话；更改后需重启应用',
              control: ClientVariantPopup(
                selected: settings.clientVariant,
                onSelected: (variant) =>
                    unawaited(_setClientVariant(context, settings, variant)),
              ),
            ),
            const Divider(height: 1),
            SettingRow(
              title: '最高播放音质',
              subtitle: '优先解析所选档位；歌曲或账户不支持时会自动逐级降低音质',
              control: PlaybackQualityPopup(
                selected: settings.maximumPlaybackQuality,
                onSelected: settings.setMaximumPlaybackQuality,
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
