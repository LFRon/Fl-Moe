import 'package:flutter/material.dart';

final class PageHeading extends StatelessWidget {
  const PageHeading({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

final class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.action,
    this.asset = 'assets/images/empty_state.png',
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;
  final String asset;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.asset(asset, width: 150, height: 150, fit: BoxFit.contain),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    ),
  );
}

void showReservedFeature(BuildContext context, String feature) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$feature入口已经保留，将在桌面适配阶段接入。')));
}

Future<bool> confirmListClear(
  BuildContext context, {
  required String listName,
  required int itemCount,
  String? consequence,
}) async {
  Future<void>? dialogCompleted;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      dialogCompleted = ModalRoute.of(
        dialogContext,
      )?.completed.then<void>((_) {});
      return AlertDialog(
        key: const ValueKey<String>('confirm-list-clear-dialog'),
        icon: const Icon(Icons.delete_sweep_outlined),
        title: Text('清空$listName？'),
        content: Text(
          <String>[
            '确定要清空$listName中的 $itemCount 首歌曲吗？',
            ?consequence,
            '这只会清空列表，不会删除歌曲文件。',
          ].join('\n'),
        ),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('cancel-list-clear'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const ValueKey<String>('confirm-list-clear'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('清空'),
          ),
        ],
      );
    },
  );
  // A pushed route's result completes when pop starts, while its overlay may
  // still be reversing. Wait for actual removal before rebuilding the list
  // beneath it, keeping semantics/render trees coherent on desktop Flutter.
  await dialogCompleted;
  return confirmed ?? false;
}
