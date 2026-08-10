import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/auth/authentication_controller.dart';
import '../../widgets/common_widgets.dart';
import 'widgets/cloud_content.dart';

final class CloudPage extends StatelessWidget {
  const CloudPage({super.key});

  @override
  Widget build(BuildContext context) => GetBuilder<AuthenticationController>(
    builder: (authentication) => Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PageHeading(
            title: '酷狗云盘',
            subtitle: '上传、匹配、分页和删除接口均在当前进程的 Dart API 中',
          ),
          const SizedBox(height: 22),
          Expanded(
            child: CloudContent(
              loggedIn: authentication.isLoggedIn,
              userId: authentication.userId,
            ),
          ),
        ],
      ),
    ),
  );
}
