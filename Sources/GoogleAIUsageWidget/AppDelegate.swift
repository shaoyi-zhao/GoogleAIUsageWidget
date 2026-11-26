import AppKit
import Foundation
import SwiftUI

final class DesktopWidgetWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: DesktopWidgetWindow?
    private var statusItem: NSStatusItem?
    private var summaryMenuItem: NSMenuItem?
    private var toggleVisibilityMenuItem: NSMenuItem?
    private var desktopLayerItem: NSMenuItem?
    private var floatingLayerItem: NSMenuItem?
    private var launchAtLoginItem: NSMenuItem?
    private var appearanceMenuItems: [AppearanceMode: NSMenuItem] = [:]
    private var intervalMenuItems: [RefreshIntervalOption: NSMenuItem] = [:]

    private let viewModel = UsageViewModel()

    private enum Keys {
        static let windowOriginX = "widget.windowOriginX"
        static let windowOriginY = "widget.windowOriginY"
        static let hasSavedOrigin = "widget.hasSavedOrigin"
    }

    private let launchAgentLabel = "io.github.shaoyi-zhao.GoogleAIUsageWidget"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupWindow()
        setupStatusItem()

        viewModel.onWindowModeChanged = { [weak self] isPinned in
            self?.applyWindowLevel(isPinnedOnTop: isPinned)
            self?.syncMenuStates()
        }
        viewModel.onStatusUpdated = { [weak self] in
            self?.syncMenuStates()
        }

        viewModel.start()
        syncMenuStates()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Window Setup

    private func setupWindow() {
        let rootView = WidgetView(viewModel: viewModel) { [weak self] height in
            self?.updateWindowHeight(height)
        }
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        let fittingSize = hostingView.fittingSize
        let initialRect = NSRect(origin: .zero, size: NSSize(width: 328, height: max(120, ceil(fittingSize.height))))

        let win = DesktopWidgetWindow(
            contentRect: initialRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.isMovableByWindowBackground = true
        win.isReleasedWhenClosed = false
        win.delegate = self
        win.contentView = hostingView

        self.window = win
        applyWindowLevel(isPinnedOnTop: viewModel.isPinnedOnTop)
        restoreOrPlaceDefaultPosition()
        win.orderFrontRegardless()
    }

    private func updateWindowHeight(_ height: CGFloat) {
        guard let window, height > 0 else { return }
        let targetHeight = ceil(height)
        guard abs(window.frame.height - targetHeight) >= 0.5 else { return }
        let newOriginY = window.frame.maxY - targetHeight
        let newFrame = NSRect(
            x: window.frame.origin.x,
            y: newOriginY,
            width: 328,
            height: targetHeight
        )
        window.setFrame(newFrame, display: true)
    }

    private func applyWindowLevel(isPinnedOnTop: Bool) {
        guard let window else { return }
        if isPinnedOnTop {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        } else {
            let desktopIconLevel = Int(CGWindowLevelForKey(.desktopIconWindow)) + 1
            window.level = NSWindow.Level(rawValue: desktopIconLevel)
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        }
    }

    private func restoreOrPlaceDefaultPosition() {
        guard let window else { return }
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Keys.hasSavedOrigin) {
            let x = defaults.double(forKey: Keys.windowOriginX)
            let y = defaults.double(forKey: Keys.windowOriginY)
            let candidate = NSPoint(x: x, y: y)
            let testFrame = NSRect(origin: candidate, size: window.frame.size)
            let isOnAnyScreen = NSScreen.screens.contains { $0.visibleFrame.intersects(testFrame) }
            if isOnAnyScreen {
                window.setFrameOrigin(candidate)
                return
            }
        }
        placeAtTopRight()
    }

    private func placeAtTopRight() {
        guard let window, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        let margin: CGFloat = 24
        let origin = NSPoint(
            x: visible.maxX - size.width - margin,
            y: visible.maxY - size.height - margin
        )
        window.setFrameOrigin(origin)
        saveWindowOrigin(origin)
    }

    private func saveWindowOrigin(_ origin: NSPoint) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: Keys.hasSavedOrigin)
        defaults.set(origin.x, forKey: Keys.windowOriginX)
        defaults.set(origin.y, forKey: Keys.windowOriginY)
    }

    func windowDidMove(_ notification: Notification) {
        guard let window else { return }
        saveWindowOrigin(window.frame.origin)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        viewModel.isWindowFocused = true
    }

    func windowDidResignKey(_ notification: Notification) {
        viewModel.isWindowFocused = false
    }

    // MARK: - Status Bar Menu

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(
                systemSymbolName: "gauge.with.dots.needle.67percent",
                accessibilityDescription: "Google AI 用量"
            )
            image?.isTemplate = true
            button.image = image
            button.toolTip = "Google AI 用量桌面组件"
        }

        let menu = NSMenu()

        let summaryItem = NSMenuItem(title: "正在加载...", action: nil, keyEquivalent: "")
        summaryItem.isEnabled = false
        menu.addItem(summaryItem)
        self.summaryMenuItem = summaryItem

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "立即刷新", action: #selector(handleRefresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let visibilityItem = NSMenuItem(title: "隐藏桌面组件", action: #selector(handleToggleVisibility), keyEquivalent: "h")
        visibilityItem.target = self
        menu.addItem(visibilityItem)
        self.toggleVisibilityMenuItem = visibilityItem

        // 窗口层级子菜单
        let layerRoot = NSMenuItem(title: "窗口层级", action: nil, keyEquivalent: "")
        let layerSubmenu = NSMenu()
        let desktopItem = NSMenuItem(title: "贴附桌面", action: #selector(handleSelectDesktopLayer), keyEquivalent: "")
        desktopItem.target = self
        let floatingItem = NSMenuItem(title: "始终置顶", action: #selector(handleSelectFloatingLayer), keyEquivalent: "")
        floatingItem.target = self
        layerSubmenu.addItem(desktopItem)
        layerSubmenu.addItem(floatingItem)
        layerRoot.submenu = layerSubmenu
        menu.addItem(layerRoot)
        self.desktopLayerItem = desktopItem
        self.floatingLayerItem = floatingItem

        // 外观子菜单
        let appearanceRoot = NSMenuItem(title: "外观风格", action: nil, keyEquivalent: "")
        let appearanceSubmenu = NSMenu()
        for mode in AppearanceMode.allCases {
            let modeItem = NSMenuItem(title: mode.title, action: #selector(handleSelectAppearance(_:)), keyEquivalent: "")
            modeItem.target = self
            modeItem.representedObject = mode.rawValue
            appearanceSubmenu.addItem(modeItem)
            appearanceMenuItems[mode] = modeItem
        }
        appearanceRoot.submenu = appearanceSubmenu
        menu.addItem(appearanceRoot)

        // 刷新频率子菜单
        let intervalRoot = NSMenuItem(title: "刷新频率", action: nil, keyEquivalent: "")
        let intervalSubmenu = NSMenu()
        for option in RefreshIntervalOption.allCases {
            let optionItem = NSMenuItem(title: option.title, action: #selector(handleSelectInterval(_:)), keyEquivalent: "")
            optionItem.target = self
            optionItem.tag = option.rawValue
            intervalSubmenu.addItem(optionItem)
            intervalMenuItems[option] = optionItem
        }
        intervalRoot.submenu = intervalSubmenu
        menu.addItem(intervalRoot)

        let resetPosItem = NSMenuItem(title: "重置组件位置", action: #selector(handleResetPosition), keyEquivalent: "")
        resetPosItem.target = self
        menu.addItem(resetPosItem)

        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "开机自动启动", action: #selector(handleToggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)
        self.launchAtLoginItem = loginItem

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        self.statusItem = item
    }

    private func syncMenuStates() {
        summaryMenuItem?.title = "\(viewModel.statusSummaryLine)（\(viewModel.lastUpdatedText)）"
        let isVisible = window?.isVisible ?? false
        toggleVisibilityMenuItem?.title = isVisible ? "隐藏桌面组件" : "显示桌面组件"

        desktopLayerItem?.state = viewModel.isPinnedOnTop ? .off : .on
        floatingLayerItem?.state = viewModel.isPinnedOnTop ? .on : .off

        for (mode, item) in appearanceMenuItems {
            item.state = (mode == viewModel.appearanceMode) ? .on : .off
        }
        for (option, item) in intervalMenuItems {
            item.state = (option == viewModel.refreshInterval) ? .on : .off
        }

        launchAtLoginItem?.state = isLaunchAgentInstalled() ? .on : .off
    }

    // MARK: - Actions

    @objc private func handleRefresh() {
        viewModel.refreshNow()
    }

    @objc private func handleToggleVisibility() {
        guard let window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.orderFrontRegardless()
        }
        syncMenuStates()
    }

    @objc private func handleSelectDesktopLayer() {
        viewModel.isPinnedOnTop = false
    }

    @objc private func handleSelectFloatingLayer() {
        viewModel.isPinnedOnTop = true
    }

    @objc private func handleSelectAppearance(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let mode = AppearanceMode(rawValue: raw) else { return }
        viewModel.appearanceMode = mode
        syncMenuStates()
    }

    @objc private func handleSelectInterval(_ sender: NSMenuItem) {
        guard let option = RefreshIntervalOption(rawValue: sender.tag) else { return }
        viewModel.refreshInterval = option
        syncMenuStates()
    }

    @objc private func handleResetPosition() {
        placeAtTopRight()
        window?.orderFrontRegardless()
        syncMenuStates()
    }

    @objc private func handleToggleLaunchAtLogin() {
        if isLaunchAgentInstalled() {
            removeLaunchAgent()
        } else {
            installLaunchAgent()
        }
        syncMenuStates()
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }

    // MARK: - LaunchAgent Management

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(launchAgentLabel).plist")
    }

    private func isLaunchAgentInstalled() -> Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    private func installLaunchAgent() {
        guard let executablePath = Bundle.main.executablePath else { return }
        let plistDict: [String: Any] = [
            "Label": launchAgentLabel,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        do {
            let dir = launchAgentURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let data = try PropertyListSerialization.data(fromPropertyList: plistDict, format: .xml, options: 0)
            try data.write(to: launchAgentURL, options: .atomic)
        } catch {
            NSSound.beep()
        }
    }

    private func removeLaunchAgent() {
        try? FileManager.default.removeItem(at: launchAgentURL)
    }
}
