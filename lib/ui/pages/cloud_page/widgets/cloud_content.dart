import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../login_dialog.dart';
import '../../../widgets/common_widgets.dart';

final class CloudContent extends StatelessWidget {
  const CloudContent({required this.loggedIn, required this.userId, super.key});

  final bool loggedIn;
  final String userId;

  @override
  Widget build(BuildContext context) => loggedIn
      ? EmptyState(
          title: '云盘账号已连接',
          message: '当前已登录酷狗用户 $userId。云盘数据表格将在下一阶段接入，这里不会启动任何后端进程。',
          asset: 'assets/images/cloud_disk.png',
          action: FilledButton.tonalIcon(
            onPressed: () => showReservedFeature(context, '云盘文件列表'),
            icon: const Icon(Icons.cloud_sync_rounded),
            label: const Text('加载云盘'),
          ),
        )
      : EmptyState(
          title: '登录后查看酷狗云盘',
          message: '二维码内容由 API 返回 URL，Flutter 使用 pretty_qr_code 在本地绘制。',
          asset: 'assets/images/cloud_disk.png',
          action: FilledButton.icon(
            onPressed: () => unawaited(showQrLoginDialog(context)),
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('扫码登录'),
          ),
        );
}
