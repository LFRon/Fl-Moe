import 'package:material_ui/material_ui.dart';

final class HomeHero extends StatelessWidget {
  const HomeHero({required this.loggedIn, required this.onAction, super.key});

  final bool loggedIn;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 238,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            scheme.primaryContainer,
            scheme.tertiaryContainer.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(34, 28, 18, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '欢迎来到 Fl-Moe',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '纯 Flutter 桌面体验，酷狗 API 直接嵌入 Dart。\n让喜欢的旋律，安静地待在你的桌面。',
                    style: TextStyle(
                      height: 1.55,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onAction,
                    icon: Icon(
                      loggedIn ? Icons.favorite_rounded : Icons.login_rounded,
                    ),
                    label: Text(loggedIn ? '进入我的音乐' : '扫码登录酷狗'),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                'assets/images/home_banner.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
