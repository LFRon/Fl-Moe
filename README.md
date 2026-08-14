# Fl-Moe

Fl-Moe 是面向 Windows 与 GNU/Linux 的 Flutter 萌音客户端。它保留萌音轻盈、可爱的产品气质，但使用 Material You 重新组织桌面界面；酷狗 API 则以纯 Dart 形式直接编译进同一个 AOT 可执行文件。

## 当前状态

- 只生成了 Linux、Windows 桌面工程，没有 macOS 工程。
- 酷狗后端直接编译进 Flutter 应用，不启动子进程、不监听 localhost，也不依赖 Node.js、WebF 或 JavaScript 引擎。
- 生产环境的 `KugouApi`、Dio、Cookie、签名、密码学与 JSON 解析驻留在长期运行的后台 Dart isolate，UI isolate 只交换可发送的强类型消息；云盘字节数据使用 `TransferableTypedData` 传输。
- 应用默认使用概念版，可在设置中即时切换标准版。两种客户端共享稳定的设备身份，但分别持久化互不兼容的登录凭据；切换只会恢复目标客户端自己的认证会话，不会跨平台复用 token。
- 参考 `KuGouMusicApi/module` 的 169 个模块提供 169 个同名路由；路由集合已经逐项比对。
- 默认网络层为 Dio，网络层通过 `KugouHttpTransport` 抽象，可在测试中完全替换。
- 已实现标准版/概念版签名、会话与设备身份、Cookie、AES、RSA、KRC、SSA、登录、二维码、云盘分片上传和听歌等级双协议。
- Analyzer 开启 strict casts、strict inference 与 strict raw types；运行时代码不使用 `dynamic`、反射或运行时脚本解释。
- 已实现 Material You 桌面外壳、自定义标题栏、可切换左右位置的窗口控制键、侧边导航、首页、发现、歌单/排行详情、搜索、音乐库、云盘入口、设置和常驻播放器；音乐库中的“我的收藏”直达“我喜欢”，账号其他歌单则在首页按创建/收藏范围筛选展示。
- 播放器使用 `media_kit`；登录后先通过 `/privilege/lite` 解析账号可用音质对应的真实 hash，再请求播放 URL。顺序、随机和列表循环都使用用户开始播放时所在的歌单、专辑或结果列表作为内存来源上下文，不提供可编辑的“播放队列”；切换到另一个列表中的歌曲会同步替换该上下文。最近播放支持确认后整表清空；最近播放与当前歌曲保存到 Hive，来源上下文不持久化，冷启动只离线恢复当前歌曲元数据，用户首次按播放时才解析 URL 并初始化音频。网络封面使用 `cached_network_image_ce`；二维码 API 只返回 URL，由 `pretty_qr_code` 在 Flutter UI 本地绘制。
- 桌面歌词与状态栏歌词本阶段只保留按钮，不绑定 Treeland 私有协议。系统托盘已作为桌面音乐播放器的常驻能力启用，提供显示/隐藏窗口、上一首、播放/暂停、下一首和退出。

## 运行

当前机器上的 Flutter 不在 `PATH` 时，可直接运行：

```bash
/home/mozixun/Develop-SDK/Flutter-SDK/flutter/bin/flutter pub get
/home/mozixun/Develop-SDK/Flutter-SDK/flutter/bin/flutter run -d linux
```

Linux runner 不强制设置 `GDK_BACKEND`。在 Wayland 会话（包括 Treeland）中由 GTK/Flutter 选择原生 Wayland 后端，同时保留传统 X11 支持。

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

酷狗当前会让未认证搜索返回业务码 152。登录完成后，`KugouSession` 会按标准版/概念版分别保存 `token`、`userid` 等认证信息，同时共享 `dfid` 等设备身份。旧版本没有记录 token 来源，首次升级会保留设备身份并要求重新登录一次，避免酷狗返回 20018。

## UI 与数据边界

`/login/qr/create` 返回 `data.url` 与 `data.content`，两者都是应编码进二维码的 H5 URL，不在 API 内生成 PNG 或 Base64 图片。Flutter 使用 `pretty_qr_code` 渲染该字符串；普通封面等真实图片 URL 交给 `cached_network_image_ce`。

Hive CE 数据与 MoeKoe Music 完全隔离：

- Linux 配置与酷狗会话：`${XDG_CONFIG_HOME:-$HOME/.config}/Fl-Moe`
- Linux 数据库：`${XDG_DATA_HOME:-$HOME/.local/share}/Fl-Moe/Hive`
- Linux 缓存：`${XDG_CACHE_HOME:-$HOME/.cache}/Fl-Moe`
- Windows 配置：`%APPDATA%\Fl-Moe`
- Windows 数据与缓存：`%LOCALAPPDATA%\Fl-Moe`

主题、强调色和窗口按钮位置即时持久化；最近播放和当前歌曲存入单独的 `library` box，应用不会保存或恢复来源列表，也不会在重启后自动播放或主动联网。升级时会从旧 `player_playback_state` 中保留当前歌曲到 `player_current_track`，随后删除其中已经废弃的队列数据。关闭键在托盘可用时固定隐藏主窗口，不再保存“关闭到托盘”开关；升级时会清除旧 `close_to_tray` 键。

窗口操作通过 `DesktopWindowService` 隔离，当前使用 Fl-Moe 魔改版 NativeApi；托盘能力通过独立的 `DesktopTrayService` 隔离。

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

GNU/Linux 优先开发，在 Wayland 会话中使用原生 Wayland，同时保留 X11；Windows 保持可运行。Linux 发行以如意玲珑的差分更新/可选自动升级为准，应用内不重复实现完整更新器。媒体会话、桌面歌词、状态栏歌词与 xdg-desktop-portal 全局快捷键属于后续平台阶段，不与内嵌 API、现有托盘服务或 UI 页面耦合。

许可证：GPL-2.0-only。
