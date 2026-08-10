import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../features/auth/authentication_controller.dart';

Future<bool> showQrLoginDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const QrLoginDialog(),
  );
  return result ?? false;
}

final class QrLoginDialog extends StatefulWidget {
  const QrLoginDialog({super.key});

  @override
  State<QrLoginDialog> createState() => _QrLoginDialogState();
}

final class _QrLoginDialogState extends State<QrLoginDialog> {
  QrLoginChallenge? _challenge;
  Timer? _timer;
  bool _loading = true;
  bool _polling = false;
  String _message = '正在向酷狗申请登录二维码…';
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_create());
  }

  Future<void> _create() async {
    _timer?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _challenge = null;
      _message = '正在向酷狗申请登录二维码…';
    });
    try {
      final challenge = await Get.find<AuthenticationController>()
          .createQrChallenge();
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _loading = false;
        _message = '请使用酷狗音乐 App 扫码登录';
      });
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) => unawaited(_poll()),
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '二维码获取失败：$error';
      });
    }
  }

  Future<void> _poll() async {
    final challenge = _challenge;
    if (_polling || challenge == null || !mounted) return;
    _polling = true;
    try {
      final result = await Get.find<AuthenticationController>()
          .checkQrChallenge(challenge);
      if (!mounted) return;
      switch (result.state) {
        case QrLoginState.waiting:
          break;
        case QrLoginState.scanned:
          setState(() {
            _message = result.nickname.isEmpty
                ? '已扫码，请在手机上确认登录'
                : '${result.nickname} 已扫码，请在手机上确认';
          });
        case QrLoginState.authorized:
          _timer?.cancel();
          Navigator.of(context).pop(true);
        case QrLoginState.expired:
          _timer?.cancel();
          setState(() {
            _message = '二维码已过期，请刷新后重试';
          });
      }
    } on Object catch (error) {
      if (mounted) {
        _timer?.cancel();
        setState(() {
          _error = '登录状态检查失败：$error';
        });
      }
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundImage: AssetImage('assets/images/app_mascot.png'),
          ),
          SizedBox(width: 12),
          Text('登录酷狗音乐'),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 230,
              height: 230,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _challenge == null
                  ? Icon(
                      Icons.qr_code_2_rounded,
                      size: 110,
                      color: scheme.error,
                    )
                  : PrettyQrView.data(
                      data: _challenge!.content.toString(),
                      decoration: const PrettyQrDecoration(
                        shape: PrettyQrSmoothSymbol(color: Color(0xFF17202E)),
                        quietZone: PrettyQrQuietZone.zero,
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            Text(
              _error ?? _message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _error == null ? scheme.onSurfaceVariant : scheme.error,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        if (!_loading && (_challenge == null || _error != null))
          FilledButton.icon(
            onPressed: () => unawaited(_create()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('刷新二维码'),
          ),
      ],
    );
  }
}
