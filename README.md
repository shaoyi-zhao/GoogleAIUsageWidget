# Google AI 用量桌面组件 (GoogleAIUsageWidget)

一个原生 macOS（SwiftUI + AppKit）扁平风格桌面组件，无需打开 Antigravity 主界面，即可在桌面实时查看你的 **Google AI（Antigravity）** 模型配额使用情况：

- **内部模型（Gemini）**：5 小时滚动配额 & 周配额的已用量、剩余量与重置倒计时
- **外部模型（Claude / GPT）**：5 小时滚动配额 & 周配额的已用量、剩余量与重置倒计时

## 功能特性

- **纯扁平极简卡片**：无阴影、无渐变、纯色细边框，支持 **跟随系统 / 扁平深色 / 扁平浅色** 三种外观模式。
- **贴附桌面 & 始终置顶一键切换**：默认贴附于桌面图层（不遮挡日常工作窗口），点击卡片右上角图钉图标或通过菜单栏即可切换为“始终置顶”。
- **拖拽自由定位**：按住卡片空白区域拖动到任意屏幕位置，自动记忆坐标。
- **低余量自动预警色**：剩余配额 `<= 30%` 进度条自动变为橙色，`<= 15%` 变为红色。
- **菜单栏快捷控制**：支持立即刷新、显示/隐藏桌面组件、调整刷新频率（1/2/5/10 分钟，默认 2 分钟）、重置位置及**开机自动启动**（通过 `LaunchAgents` 管理）。
- **休眠唤醒自动同步**：Mac 从休眠状态唤醒后自动延迟刷新最新配额。

## 运行前提

1. **硬件与系统**：Apple Silicon（`arm64`）Mac，**macOS 14.0 (Sonoma)** 及以上版本。
2. **已安装并登录 Antigravity CLI (`agy`)**：
   - 在终端运行 `agy` 并按提示完成 Google 账号登录。
   - 本组件支持在 `~/.local/bin/agy`、`/opt/homebrew/bin/agy`、`/usr/local/bin/agy` 或 `PATH` 中自动查找 `agy`。

## 安装与使用（从 Release 下载）

1. 前往本仓库 [Releases](https://github.com/shaoyi-zhao/GoogleAIUsageWidget/releases) 页面，下载最新版 `GoogleAIUsageWidget-v1.0.0-arm64.zip` 并解压。
2. 将解压得到的 `GoogleAIUsageWidget.app` 拖入 `/Applications`（应用程序）目录。
3. **首次打开说明（重要）**：
   由于本应用为开源自签名版本（未经 Apple Developer 公证），首次双击打开时 macOS 可能会提示“无法验证开发者”或“已损坏”。请在终端运行以下命令移除系统隔离属性并启动：
   ```bash
   xattr -cr /Applications/GoogleAIUsageWidget.app
   open /Applications/GoogleAIUsageWidget.app
   ```
4. 启动后，桌面右上角会出现用量卡片，顶部菜单栏也会出现仪表盘图标：
   - **拖动位置**：按住卡片空白处即可移动。
   - **置顶切换**：点击卡片右上角的图钉图标，或在菜单栏选择 **窗口层级 -> 贴附桌面 / 始终置顶**。
   - **设置开机自启**：建议先将应用放入 `/Applications` 后，再在菜单栏勾选 **开机自动启动**。

## 从源码自行构建

```bash
git clone https://github.com/shaoyi-zhao/GoogleAIUsageWidget.git
cd GoogleAIUsageWidget
./build_app.sh
```

构建完成后，应用包位于 `build/GoogleAIUsageWidget.app`。运行单元测试可使用：

```bash
swift test --disable-sandbox
```

## 数据来源与隐私说明

- 本工具仅在本地通过子进程调用官方 CLI `agy -p /usage --output-format json --print-timeout 25s` 获取配额 JSON（不消耗模型 token）。
- 所有数据仅在本地展示，不收集、不存储、不向任何第三方服务器上传你的账号或使用信息。

## License

[MIT](LICENSE)
