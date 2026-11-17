import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

import '../features/navigation/app_navigation_controller.dart';
import 'scrolling/fl_moe_smooth_scroll.dart';

final class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  static const List<_NavigationItem> _items = <_NavigationItem>[
    _NavigationItem(AppSection.home, Icons.home_rounded, '首页'),
    _NavigationItem(AppSection.discover, Icons.explore_rounded, '发现'),
    _NavigationItem(AppSection.search, Icons.search_rounded, '搜索'),
    _NavigationItem(AppSection.library, Icons.library_music_rounded, '音乐库'),
    _NavigationItem(AppSection.cloud, Icons.cloud_rounded, '云盘'),
    _NavigationItem(AppSection.settings, Icons.tune_rounded, '设置'),
  ];

  @override
  Widget build(BuildContext context) => GetBuilder<AppNavigationController>(
    builder: (navigation) {
      final selected = navigation.section;
      final scheme = Theme.of(context).colorScheme;
      return Container(
        width: 92,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.65),
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 14),
            const CircleAvatar(
              radius: 25,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/images/app_mascot.png'),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SilkyListView.separated(
                silkyConfig: flMoeSmoothScrollConfig,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 5),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final active =
                      item.section == selected ||
                      (selected == AppSection.collection &&
                          item.section == AppSection.discover);
                  return Tooltip(
                    message: item.label,
                    preferBelow: false,
                    child: Material(
                      color: active
                          ? scheme.primaryContainer.withValues(alpha: 0.75)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        mouseCursor: WidgetStateMouseCursor.clickable,
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => navigation.goTo(item.section),
                        child: SizedBox(
                          height: 62,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                item.icon,
                                size: 22,
                                color: active ? scheme.primary : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active ? scheme.primary : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'FL·MOE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

final class _NavigationItem {
  const _NavigationItem(this.section, this.icon, this.label);

  final AppSection section;
  final IconData icon;
  final String label;
}
