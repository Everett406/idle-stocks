# 股海大亨 (Idle Stocks)

> 24 小时持续运转的虚拟股市放置手游。

![Banner](docs/banner.png)

一款纯单机的 Flutter Android 放置/增量游戏：模拟一个永不停歇的虚拟股市，玩家在碎片时间
里看行情、做交易、收分红、升级、转生，逐步从散户成长为传奇经理。

- 平台：仅 Android (`flutter build apk --release`)
- 存档：本地 `shared_preferences` JSON（key: `save_v1`）
- 网络：完全离线，不收集任何数据

---

## 玩法速览

- **市场**：顶部行情条跑马灯 + 股票卡列表（迷你走势图）。点开进入详情分时图。
- **持仓**：资产总览 + 每只股票的持仓盈亏、迷你走势图、快捷卖出。
- **成长**：升级、每日任务、夜盘激战提示、转生。
- **设置**（持仓页右上角）：深色金融终端 / 浅色清爽 App / 跟随系统。
- **离线收益**：进入应用时若距上次保存超过 60 秒，会先结算最长 8 小时的离线分红。

---

## 技术栈

| 项 | 选择 | 备注 |
| - | - | - |
| 框架 | Flutter 3.24.5 / Dart 3.5 | 单代码库，UI 渲染一致 |
| 状态 | `ChangeNotifier` + 单 `Timer` 驱动 | 简单可读，无外部依赖 |
| 持久化 | `shared_preferences: ^2.2.3` | 单 JSON key: `save_v1` |
| 音效 | `audioplayers: ^5.2.1` | 每个音效独立 `AudioPlayer` 实例 |
| 数字格式化 | `intl: ^0.19.0` | 金额/百分比本地化 |
| 设计 | Material 3 + 自定义色板 | 红涨绿跌（中国习惯） |

选择 Flutter 的理由：跨平台 UI 渲染一致，动画体系 (`AnimationController` /
`CustomPainter`) 完整，Material 3 主题切换体验原生，无需任何原生侧定制即可达成
复杂的金融终端视觉风格与细腻的过渡动画。

---

## 本地运行

需要 Flutter 3.24+ 与 Android SDK / 模拟器。

```bash
flutter pub get
flutter run            # 连真机或启动模拟器
flutter test           # 跑测试
```

## 构建 APK

```bash
flutter build apk --release \
  --build-name=$(cat version.txt) \
  --build-number=$GITHUB_RUN_NUMBER \
  --dart-define=APP_VERSION=$(cat version.txt)
```

产物：`build/app/outputs/flutter-apk/app-release.apk`

---

## 版本号管理

`version.txt` 是项目内**唯一**的版本号来源（`X.Y.Z`）。

| 位置 | 内容 | 写入方式 |
| - | - | - |
| `version.txt` | `0.1.0` | 手动修改 |
| `pubspec.yaml` | `version: 0.1.0+1` | 手动修改（与 version.txt 一致） |
| 应用内设置页 | `APP_VERSION` | CI 通过 `--dart-define=APP_VERSION=...` 注入 |
| Git tag | `v0.1.0` | 手动 `git tag` |
| APK `versionCode`/`versionName` | `1` / `0.1.0` | CI 读 `version.txt` 并通过 `--build-name`/`--build-number` 传入 |

发布前流程：

1. 改 `version.txt` 和 `pubspec.yaml`（同步）
2. 更新 `CHANGELOG.md`、`docs/GDD.md` 等
3. `git add -A && git commit && git push`
4. `git tag v0.1.0 && git push origin v0.1.0`
5. CI 触发，校验 tag 与 `version.txt` 一致 → 编译 → 上传 release

---

## CI / Release

`.github/workflows/release.yml`：

- 触发条件：`push tags v*` 或 `workflow_dispatch`
- 校验 tag (`vX.Y.Z`) 与 `version.txt` (`X.Y.Z`) 一致，不一致则终止
- 解码 `secrets.SIGNING_KEY` (base64) 生成 `android/app/key.jks`
- 写 `android/key.properties` (`storePassword` / `keyAlias` / `keyPassword`)
- `flutter build apk --release` → `softprops/action-gh-release@v2` 上传
- 产物作为 GitHub Release asset，`docs/releases/vX.Y.Z.md` 作为 body

### 所需 GitHub Secrets

| Secret | 内容 |
| - | - |
| `SIGNING_KEY` | `base64` 编码后的 `key.jks` 文件内容 |
| `KEYSTORE_PASSWORD` | keystore 密码 |
| `KEY_ALIAS` | key alias |
| `KEY_PASSWORD` | key 密码 |

### 生成 keystore 示例

```bash
keytool -genkey -v \
  -keystore android/app/key.jks \
  -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias idle-stocks \
  -storepass 'YOUR_STORE_PASS' \
  -keypass 'YOUR_KEY_PASS' \
  -dname "CN=IdleStocks,O=Personal,C=CN"
base64 -w0 android/app/key.jks > signing_key.b64
```

本地开发时**没有** `android/key.properties` 也可正常编译 — `app/build.gradle` 检测不到
则用 debug 签名。

---

## 目录结构

```
.
├── android/                # 原生壳工程（Gradle / Kotlin）
├── assets/sounds/          # 5 个 WAV 音效
├── docs/                   # 设计文档与发布说明
├── lib/
│   ├── core/               # 常量表、数字格式化、GBM 工具
│   ├── models/             # 股票/持仓/升级/任务/事件 数据类
│   ├── engine/             # 模拟/分红/事件/任务/转生/存档
│   ├── services/           # 音频服务
│   ├── ui/                 # 应用框架、页面、动画组件
│   └── main.dart           # 入口
├── scripts/generate_assets.js   # 重新生成音效 (Node 22)
├── version.txt             # 唯一版本来源
└── .github/workflows/release.yml
```

---

## License

仅供学习与个人使用。游戏内所有股票/公司名称均为虚构，如有雷同纯属巧合。