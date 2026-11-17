import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../core/window/desktop_window_service.dart';
import '../core/tray/desktop_tray_service.dart';
import '../features/auth/authentication_controller.dart';
import '../features/music/music_catalog_controller.dart';
import '../features/navigation/app_navigation_controller.dart';
import '../features/settings/app_settings_controller.dart';
import 'login_dialog.dart';
import 'widgets/network_artwork.dart';
import 'window_drag_region.dart';

final class FlMoeTitleBar extends StatefulWidget {
  const FlMoeTitleBar({required this.window, required this.tray, super.key});

  final DesktopWindowService window;
  final DesktopTrayService tray;

  @override
  State<FlMoeTitleBar> createState() => _FlMoeTitleBarState();
}

final class _FlMoeTitleBarState extends State<FlMoeTitleBar> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _submitSearch(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    Get.find<AppNavigationController>().openSearch(query);
    await Get.find<MusicSearchController>().search(query);
  }

  Future<void> _refreshCurrentContent() async {
    final navigation = Get.find<AppNavigationController>();
    switch (navigation.section) {
      case AppSection.home:
        await Get.find<MusicCatalogController>().refreshHomeCatalog();
        return;
      case AppSection.discover:
        await Get.find<MusicCatalogController>().refreshDiscoverCatalog();
        return;
      case AppSection.collection:
        final collection = navigation.selectedCollection;
        if (collection != null) {
          await Get.find<MusicCollectionDetailController>().load(collection);
        }
        return;
      case AppSection.search:
        final search = Get.find<MusicSearchController>();
        if (search.query.isNotEmpty) await search.search(search.query);
        return;
      case AppSection.library || AppSection.cloud || AppSection.settings:
        return;
    }
  }

  Future<void> _closeWindow() async {
    if (widget.tray.isAvailable) {
      await widget.window.hide();
      return;
    }
    await widget.window.close();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AppSettingsController>(
    builder: (settings) => GetBuilder<AuthenticationController>(
      builder: (authentication) {
        final controlSide = settings.windowControlSide;
        final controls = FlMoeWindowControls(
          window: widget.window,
          onClose: _closeWindow,
        );
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: SizedBox(
            height: 52,
            child: Row(
              children: <Widget>[
                if (controlSide == WindowControlSide.left) controls,
                const SizedBox(width: 8),
                IconButton(
                  tooltip: '首页',
                  onPressed: () =>
                      Get.find<AppNavigationController>().goTo(AppSection.home),
                  icon: const Icon(Icons.home_outlined, size: 20),
                ),
                IconButton(
                  tooltip: '刷新当前内容',
                  onPressed: () => unawaited(_refreshCurrentContent()),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
                FlMoeWindowDragRegion(window: widget.window, width: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      controller: _search,
                      onSubmitted: (value) => unawaited(_submitSearch(value)),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: '搜索歌曲、歌手、专辑或歌单',
                        prefixIcon: const Icon(Icons.search_rounded, size: 19),
                        suffixIcon: IconButton(
                          tooltip: '搜索',
                          onPressed: () =>
                              unawaited(_submitSearch(_search.text)),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FlMoeWindowDragRegion(
                    key: const ValueKey<String>('window-drag-region'),
                    window: widget.window,
                  ),
                ),
                if (authentication.isLoggedIn)
                  PopupMenuButton<String>(
                    tooltip: '酷狗账号',
                    borderRadius: BorderRadius.circular(20),
                    splashRadius: 20,
                    onSelected: (value) {
                      if (value == 'logout') {
                        unawaited(authentication.signOut());
                      }
                    },
                    popUpAnimationStyle: const AnimationStyle(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    ),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          authentication.nickname.isEmpty
                              ? '酷狗用户 ${authentication.userId}'
                              : authentication.nickname,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('退出登录'),
                      ),
                    ],
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: SizedBox.square(
                        key: const ValueKey<String>('kugou-account-button'),
                        dimension: 40,
                        child: Center(
                          child: NetworkArtwork(
                            key: const ValueKey<String>('kugou-account-avatar'),
                            url: authentication.avatarUrl,
                            size: 30,
                            borderRadius: 15,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () async {
                      final success = await showQrLoginDialog(context);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('酷狗账号登录成功')),
                        );
                      }
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text('登录'),
                  ),
                const SizedBox(width: 4),
                if (controlSide == WindowControlSide.right) controls,
              ],
            ),
          ),
        );
      },
    ),
  );
}

final class FlMoeWindowControls extends StatelessWidget {
  const FlMoeWindowControls({required this.window, this.onClose, super.key});

  final DesktopWindowService window;
  final AsyncCallback? onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _TrafficButton(
          tooltip: '最小化',
          color: const Color(0xFFFFBD2E),
          icon: Icons.remove_rounded,
          onPressed: () => unawaited(window.minimize()),
        ),
        const SizedBox(width: 9),
        _TrafficButton(
          tooltip: '最大化 / 还原',
          color: const Color(0xFF28C840),
          icon: Icons.crop_square_rounded,
          onPressed: () => unawaited(window.toggleMaximize()),
        ),
        const SizedBox(width: 9),
        _TrafficButton(
          tooltip: '关闭',
          color: const Color(0xFFFF5F57),
          icon: Icons.close_rounded,
          onPressed: () => unawaited((onClose ?? window.close)()),
        ),
      ],
    ),
  );
}

final class _TrafficButton extends StatefulWidget {
  const _TrafficButton({
    required this.tooltip,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_TrafficButton> createState() => _TrafficButtonState();
}

final class _TrafficButtonState extends State<_TrafficButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: widget.tooltip,
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) => setState(() => _hovered = true),
      onExit: (event) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: _hovered
                ? <BoxShadow>[
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: 7,
                    ),
                  ]
                : null,
          ),
          child: _hovered
              ? Icon(widget.icon, size: 10, color: Colors.black54)
              : null,
        ),
      ),
    ),
  );
}
