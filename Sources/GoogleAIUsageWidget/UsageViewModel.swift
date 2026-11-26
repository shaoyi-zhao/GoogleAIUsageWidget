import AppKit
import Combine
import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case dark = "dark"
    case light = "light"

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .dark: return "深色毛玻璃"
        case .light: return "浅色毛玻璃"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

enum RefreshIntervalOption: Int, CaseIterable {
    case oneMinute = 60
    case twoMinutes = 120
    case fiveMinutes = 300
    case tenMinutes = 600

    var title: String {
        switch self {
        case .oneMinute: return "每 1 分钟"
        case .twoMinutes: return "每 2 分钟"
        case .fiveMinutes: return "每 5 分钟"
        case .tenMinutes: return "每 10 分钟"
        }
    }
}

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var now: Date = Date()
    @Published var isWindowFocused: Bool = false
    @Published var isDesktopFocused: Bool = false
    @Published var isHovered: Bool = false

    var isVibrant: Bool {
        isWindowFocused || isDesktopFocused || isHovered
    }

    @Published var isPinnedOnTop: Bool {
        didSet {
            defaults.set(isPinnedOnTop, forKey: Keys.pinnedOnTop)
            onWindowModeChanged?(isPinnedOnTop)
        }
    }

    @Published var appearanceMode: AppearanceMode {
        didSet {
            defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
        }
    }

    @Published var refreshInterval: RefreshIntervalOption {
        didSet {
            defaults.set(refreshInterval.rawValue, forKey: Keys.refreshInterval)
            restartRefreshTimer()
        }
    }

    var onWindowModeChanged: ((Bool) -> Void)?
    var onStatusUpdated: (() -> Void)?

    private enum Keys {
        static let pinnedOnTop = "widget.pinnedOnTop"
        static let appearanceMode = "widget.appearanceMode"
        static let refreshInterval = "widget.refreshInterval"
    }

    private let service = UsageService()
    private let defaults = UserDefaults.standard
    private var refreshTimer: Timer?
    private var clockTimer: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var appActivateObserver: NSObjectProtocol?

    init() {
        self.isPinnedOnTop = defaults.bool(forKey: Keys.pinnedOnTop)
        if let rawAppearance = defaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: rawAppearance) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .dark
        }
        let savedInterval = defaults.integer(forKey: Keys.refreshInterval)
        self.refreshInterval = RefreshIntervalOption(rawValue: savedInterval) ?? .twoMinutes

        setupObservers()
    }

    deinit {
        refreshTimer?.invalidate()
        clockTimer?.invalidate()
        if let wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
        }
        if let appActivateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(appActivateObserver)
        }
    }

    func start() {
        restartRefreshTimer()
        startClockTimer()
        refreshNow()
    }

    func refreshNow() {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil
        onStatusUpdated?()

        Task {
            do {
                let result = try await service.fetchUsage()
                self.snapshot = result
                self.now = Date()
                self.errorMessage = nil
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isRefreshing = false
            self.onStatusUpdated?()
        }
    }

    var lastUpdatedText: String {
        guard let fetchedAt = snapshot?.fetchedAt else {
            return isRefreshing ? "更新中..." : "尚未获取"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = formatter.string(from: fetchedAt)
        return isRefreshing ? "刷新中..." : "更新于 \(timeStr)"
    }

    var statusSummaryLine: String {
        guard let snapshot else {
            return isRefreshing ? "正在获取配额..." : "暂无配额数据"
        }
        let internal5h = snapshot.internalGroup?.fiveHourBucket?.remainingText ?? "--"
        let external5h = snapshot.externalGroup?.fiveHourBucket?.remainingText ?? "--"
        return "内部5h剩余 \(internal5h) · 外部5h剩余 \(external5h)"
    }

    private func setupObservers() {
        updateDesktopFocusState(bundleID: NSWorkspace.shared.frontmostApplication?.bundleIdentifier)

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                self?.refreshNow()
            }
        }

        appActivateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bundleID = app?.bundleIdentifier
            Task { @MainActor [weak self] in
                self?.updateDesktopFocusState(bundleID: bundleID)
            }
        }
    }

    private func updateDesktopFocusState(bundleID: String?) {
        let selfID = Bundle.main.bundleIdentifier
        isDesktopFocused = (bundleID == "com.apple.finder" || (selfID != nil && bundleID == selfID))
    }

    private func restartRefreshTimer() {
        refreshTimer?.invalidate()
        let interval = TimeInterval(refreshInterval.rawValue)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNow()
            }
        }
    }

    private func startClockTimer() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.now = Date()
            }
        }
    }
}
