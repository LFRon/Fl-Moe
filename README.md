# Fl-Moe

Fl-Moe 是面向 Windows 与 GNU/Linux 的 Flutter 萌音客户端。当前阶段已经完成仓库初始化，以及内嵌式纯 Dart 酷狗 API 的第一版实现。

## 当前状态

- 只生成了 Linux、Windows 桌面工程，没有 macOS 工程。
- 酷狗后端直接编译进 Flutter 应用，不启动子进程、不监听 localhost，也不依赖 Node.js、WebF 或 JavaScript 引擎。
- 参考 `KuGouMusicApi/module` 的 169 个模块提供 169 个同名路由；路由集合已经逐项比对。
- 默认网络层为 Dio，网络层通过 `KugouHttpTransport` 抽象，可在测试中完全替换。
- 已实现标准版/概念版签名、会话与设备身份、Cookie、AES、RSA、KRC、SSA、登录、二维码、云盘分片上传和听歌等级双协议。
- Analyzer 开启 strict casts、strict inference 与 strict raw types；运行时代码不使用 `dynamic`、反射或运行时脚本解释。

Flutter UI 尚未开始复刻，目前 `lib/main.dart` 仍是 Flutter 初始化模板。

## 使用

```dart
import 'package:fl_moe/kugou_api.dart';

final api = KugouApi();

final hotWords = await api.hotSearch();

final playback = await api.resolveSongUrl(
  const KugouSongUrlQuery(
    hash: 'song-hash',
    quality: KugouPlaybackQuality.high,
  ),
);

// API 返回二维码的原始内容 URL；图片渲染属于 Flutter UI。
final qrContent = await api.loginQrContent('qr-key');

api.close();
```

常用功能优先使用 `KugouTypedApi` 强类型方法。尚未建立专用请求模型的兼容接口可以通过统一实例调用：

```dart
final response = await api.callJson(
  '/rank/list',
  parameters: <String, Object?>{'withsong': 1},
);
```

`KugouApi.call` 是最后一级原始协议边界，可处理 JSON 以外的二进制或文本响应。`Object?` 只保留在外部 JSON/二进制协议边界，应用代码无需依赖 `dynamic` 推断。

酷狗当前会让未认证搜索返回业务码 152。登录完成后，`KugouSession` 会保存 `token`、`userid`、`dfid` 等身份信息并由后续请求复用。

## 二维码与网络图片边界

`/login/qr/create` 返回 `data.url` 与 `data.content`，两者都是应编码进二维码的 H5 URL，不在 API 内生成 PNG 或 Base64 图片。UI 阶段计划用 `pretty_qr_code` 渲染这个字符串；普通封面等真实图片 URL 则适合交给 `cached_network_image_ce`。这两个 UI 依赖目前没有加入后端阶段的依赖树。

## 验证

```bash
flutter analyze
flutter test
```

真实网关冒烟测试默认跳过，以免普通测试依赖外网：

```bash
KUGOU_LIVE_TEST=1 flutter test test/kugou_api/live_smoke_test.dart
```

认证搜索测试还需要显式提供测试账号 Cookie：

```bash
KUGOU_LIVE_TEST=1 \
KUGOU_LIVE_COOKIE='token=...; userid=...; dfid=...' \
flutter test test/kugou_api/live_smoke_test.dart
```

## 静态生成器

`tool/generate_kugou_endpoints.py` 是开发期迁移工具，只读取上游的普通声明式 JavaScript 模块并输出静态 Dart 源码。生成结果已经提交到 `lib/kugou_api/src/endpoints/generated_endpoints.dart`；应用构建、AOT 编译和运行都不需要 Python 或 JavaScript。

需要同步上游普通模块时：

```bash
python3 -m venv .generator-venv
.generator-venv/bin/pip install -r tool/requirements-kugou-generator.txt
.generator-venv/bin/python tool/generate_kugou_endpoints.py \
  ../KuGouMusicApi/module \
  lib/kugou_api/src/endpoints/generated_endpoints.dart
dart format lib/kugou_api/src/endpoints/generated_endpoints.dart
```

复杂模块由手写 Dart 实现，生成器遇到不支持的 JavaScript 结构会明确跳过，不会在运行时回退到 JS。

## 平台方向

GNU/Linux 将优先开发，并以原生 Wayland 会话为目标；Windows 随后保持可运行。窗口、播放器、媒体会话、桌面歌词和 xdg-desktop-portal 等桌面集成属于后续 UI/平台阶段，不与内嵌 API 耦合。

许可证：GPL-3.0。
