# Google AI 用量桌面组件 (GoogleAIUsageWidget)

一个原生 macOS（SwiftUI + AppKit）透明毛玻璃桌面组件，无需打开 Antigravity 主界面，即可在桌面实时查看你的 **Google AI（Antigravity）** 模型配额使用情况：

- **内部模型（Gemini）**：5 小时滚动配额 & 周配额的已用量、剩余量与重置倒计时
- **外部模型（Claude / GPT）**：5 小时滚动配额 & 周配额的已用量、剩余量与重置倒计时

## 功能特性

- **原生透明毛玻璃质感**：基于 `NSVisualEffectView` 实时混合桌面壁纸，配合 `24pt` 连续大圆角与细高光玻璃描边，支持 **深色毛玻璃 / 浅色毛玻璃 / 跟随系统** 三种外观模式。
- **聚焦彩色 / 失焦单色双态切换**：切到其他 App 工作时自动收敛为克制的单色半透明玻璃；点击桌面、点击组件或鼠标悬停时平滑过渡为柔和彩色渐变状态（低余量 `<= 30%` 变琥珀色，`<= 15%` 变珊瑚红色）。
- **一体胶囊进度条**：圆润胶囊底槽搭配平滑渐变填充，清晰直观展示剩余配额比例。
- **贴附桌面 & 始终置顶一键切换**：默认贴附于桌面图层（不遮挡日常工作窗口），点击卡片右上角图钉图标或通过菜单栏即可切换为“始终置顶”。
- **拖拽自由定位**：按住卡片空白区域拖动到任意屏幕位置，自动记忆坐标。
- **菜单栏快捷控制**：支持立即刷新、显示/隐藏桌面组件、调整刷新频率（1/2/5/10 分钟，默认 2 分钟）、重置位置及**开机自动启动**（通过 `LaunchAgents` 管理）。
- **休眠唤醒自动同步**：Mac 从休眠状态唤醒后自动延迟刷新最新配额。

## 运行前提

1. **硬件与系统**：Apple Silicon（`arm64`）Mac，**macOS 14.0 (Sonoma)** 及以上版本。
2. **已安装并登录 Antigravity CLI (`agy`)**：
   - 在终端运行 `agy` 并按提示完成 Google 账号登录。
   - 本组件支持在 `~/.local/bin/agy`、`/opt/homebrew/bin/agy`、`/usr/local/bin/agy` 或 `PATH` 中自动查找 `agy`。

## 安装与使用（从 Release 下载）

1. 前往本仓库 [Releases](https://github.com/shaoyi-zhao/GoogleAIUsageWidget/releases) 页面，下载最新版 `GoogleAIUsageWidget-v1.1.0-arm64.zip` 并解压。
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
