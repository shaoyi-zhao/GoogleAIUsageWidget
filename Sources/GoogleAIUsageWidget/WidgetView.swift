import AppKit
import SwiftUI

struct VisualEffectGlassView: NSViewRepresentable {
    let colorScheme: ColorScheme

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        view.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        view.wantsLayer = true
        view.layer?.cornerRadius = 24
        view.layer?.cornerCurve = .continuous
        view.layer?.masksToBounds = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.blendingMode = .behindWindow
        nsView.state = .active
        nsView.material = .hudWindow
        nsView.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        nsView.wantsLayer = true
        nsView.layer?.cornerRadius = 24
        nsView.layer?.cornerCurve = .continuous
        nsView.layer?.masksToBounds = true
    }
}

struct GlassPalette {
    let isDark: Bool
    let isVibrant: Bool
    let tintOverlay: Color
    let borderGradient: LinearGradient
    let subcardFill: Color
    let subcardStroke: Color
    let pillFill: Color
    let primaryText: Color
    let secondaryText: Color
    let tertiaryText: Color
    let barTrackFill: Color
    let monoBarFill: Color
    let internalIconColor: Color
    let externalIconColor: Color
    let internalBarGradient: LinearGradient
    let externalBarGradient: LinearGradient
    let warningBarGradient: LinearGradient
    let dangerBarGradient: LinearGradient
    let activePinFill: Color
    let healthyDot: Color
    let warningAccent: Color
    let dangerAccent: Color
    let errorBackground: Color
    let errorText: Color

    static func forScheme(_ scheme: ColorScheme, isVibrant: Bool) -> GlassPalette {
        if scheme == .dark {
            let monoFill = Color.white.opacity(0.75)
            return GlassPalette(
                isDark: true,
                isVibrant: isVibrant,
                tintOverlay: Color.black.opacity(isVibrant ? 0.14 : 0.22),
                borderGradient: LinearGradient(
                    colors: [
                        Color.white.opacity(isVibrant ? 0.36 : 0.24),
                        Color.white.opacity(0.08),
                        Color.white.opacity(isVibrant ? 0.22 : 0.14)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                subcardFill: Color.white.opacity(isVibrant ? 0.08 : 0.06),
                subcardStroke: Color.white.opacity(isVibrant ? 0.12 : 0.08),
                pillFill: Color.white.opacity(isVibrant ? 0.12 : 0.09),
                primaryText: Color.white.opacity(isVibrant ? 0.95 : 0.86),
                secondaryText: Color.white.opacity(isVibrant ? 0.68 : 0.56),
                tertiaryText: Color.white.opacity(0.46),
                barTrackFill: Color.white.opacity(0.14),
                monoBarFill: monoFill,
                internalIconColor: isVibrant ? Color(hex: 0x60A5FA) : Color.white.opacity(0.60),
                externalIconColor: isVibrant ? Color(hex: 0x34D399) : Color.white.opacity(0.60),
                internalBarGradient: LinearGradient(
                    colors: isVibrant
                        ? [Color(hex: 0x60A5FA), Color(hex: 0xA78BFA)]
                        : [monoFill, monoFill],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                externalBarGradient: LinearGradient(
                    colors: isVibrant
                        ? [Color(hex: 0x34D399), Color(hex: 0x2DD4BF)]
                        : [monoFill, monoFill],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                warningBarGradient: LinearGradient(
                    colors: isVibrant
                        ? [Color(hex: 0xFBBF24), Color(hex: 0xF59E0B)]
                        : [monoFill, monoFill],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                dangerBarGradient: LinearGradient(
                    colors: isVibrant
                        ? [Color(hex: 0xFB7185), Color(hex: 0xEF4444)]
                        : [monoFill, monoFill],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                activePinFill: isVibrant ? Color(hex: 0x60A5FA) : Color.white.opacity(0.85),
                healthyDot: isVibrant ? Color(hex: 0x34D399) : Color.white.opacity(0.60),
                warningAccent: isVibrant ? Color(hex: 0xFBBF24) : Color.white.opacity(0.65),
                dangerAccent: isVibrant ? Color(hex: 0xF87171) : Color.white.opacity(0.75),
                errorBackground: Color(hex: 0xEF4444, opacity: isVibrant ? 0.24 : 0.14),
                errorText: Color(hex: 0xFECACA)
            )
        } else {
            let monoFill = Color.black.opacity(0.65)
            return GlassPalette(
                isDark: false,
                isVibrant: isVibrant,
                tintOverlay: Color.white.opacity(isVibrant ? 0.14 : 0.22),
                borderGradient: LinearGradient(
                    colors: [
                        Color.white.opacity(isVibrant ? 0.80 : 0.65),
                        Color.white.opacity(0.25),
                        Color.white.opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                subcardFill: Color.black.opacity(isVibrant ? 0.05 : 0.04),
                subcardStroke: Color.black.opacity(0.08),
                pillFill: Color.black.opacity(isVibrant ? 0.07 : 0.05),
                primaryText: Color.black.opacity(isVibrant ? 0.90 : 0.80),
                secondaryText: Color.black.opacity(isVibrant ? 0.58 : 0.50),
                tertiaryText: Color.black.opacity(0.42),
                barTrackFill: Color.black.opacity(0.10),
                monoBarFill: monoFill,
                internalIconColor: isVibrant ? Color(hex: 0x2563EB) : Color.black.opacity(0.50),
                externalIconColor: isVibrant ? Color(hex: 0x059669) : Color.black.opacity(0.50),
                internalBarGradient: LinearGradient(
                    colors: isVibrant
                        ? [Color(hex: 0x3B82F6), Color(hex: 0x8B5CF6)]
                        : [monoFill, monoFill],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                externalBarGradient: LinearGradient(
                    colors: isVibrant
                        ? [Color(hex: 0x10B981), Color(hex: 0x14B8A6)]
                        : [monoFill, monoFill],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                warningBarGradient: LinearGradient(
                    colors: isVibrant
                        ? [Color(hex: 0xF59E0B), Color(hex: 0xD97706)]
                        : [monoFill, monoFill],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                dangerBarGradient: LinearGradient(
                    colors: isVibrant
                        ? [Color(hex: 0xF43F5E), Color(hex: 0xDC2626)]
                        : [monoFill, monoFill],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                activePinFill: isVibrant ? Color(hex: 0x2563EB) : Color.black.opacity(0.75),
                healthyDot: isVibrant ? Color(hex: 0x10B981) : Color.black.opacity(0.48),
                warningAccent: isVibrant ? Color(hex: 0xD97706) : Color.black.opacity(0.55),
                dangerAccent: isVibrant ? Color(hex: 0xDC2626) : Color.black.opacity(0.65),
                errorBackground: Color(hex: 0xDC2626, opacity: isVibrant ? 0.16 : 0.10),
                errorText: Color(hex: 0x991B1B)
            )
        }
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

struct WidgetView: View {
    @ObservedObject var viewModel: UsageViewModel
    var onHeightChange: ((CGFloat) -> Void)? = nil
    @Environment(\.colorScheme) private var systemColorScheme

    private var effectiveColorScheme: ColorScheme {
        viewModel.appearanceMode.preferredColorScheme ?? systemColorScheme
    }

    private var palette: GlassPalette {
        GlassPalette.forScheme(effectiveColorScheme, isVibrant: viewModel.isVibrant)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerBar

            if let errorMessage = viewModel.errorMessage {
                errorBanner(errorMessage)
            }

            if let snapshot = viewModel.snapshot {
                GlassGroupSectionView(
                    title: "内部模型",
                    subtitle: "Gemini",
                    symbolName: "sparkles",
                    iconColor: palette.internalIconColor,
                    groupGradient: palette.internalBarGradient,
                    group: snapshot.internalGroup,
                    palette: palette,
                    now: viewModel.now
                )

                GlassGroupSectionView(
                    title: "外部模型",
                    subtitle: "Claude / GPT",
                    symbolName: "cpu",
                    iconColor: palette.externalIconColor,
                    groupGradient: palette.externalBarGradient,
                    group: snapshot.externalGroup,
                    palette: palette,
                    now: viewModel.now
                )
            } else {
                loadingPlaceholder
            }
        }
        .padding(16)
        .frame(width: 328)
        .fixedSize(horizontal: false, vertical: true)
        .background {
            ZStack {
                VisualEffectGlassView(colorScheme: effectiveColorScheme)
                palette.tintOverlay
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(palette.borderGradient, lineWidth: 1)
        )
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { onHeightChange?(proxy.size.height) }
                    .onChange(of: proxy.size.height) { _, newHeight in
                        onHeightChange?(newHeight)
                    }
            }
        )
        .onHover { hovering in
            viewModel.isHovered = hovering
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isVibrant)
        .environment(\.colorScheme, effectiveColorScheme)
    }

    private var headerBar: some View {
        HStack(spacing: 6) {
            Text("Google AI 用量")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.primaryText)

            Spacer(minLength: 4)

            HStack(spacing: 5) {
                Circle()
                    .fill(statusDotColor)
                    .frame(width: 6, height: 6)

                Text(pillTimeText)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                    .monospacedDigit()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(palette.pillFill)
            .clipShape(Capsule())

            Button {
                viewModel.isPinnedOnTop.toggle()
            } label: {
                Image(systemName: viewModel.isPinnedOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(viewModel.isPinnedOnTop ? palette.activePinFill : palette.secondaryText)
                    .frame(width: 24, height: 24)
                    .background(palette.pillFill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(viewModel.isPinnedOnTop ? "当前：始终置顶（点击切换贴附桌面）" : "当前：贴附桌面（点击切换始终置顶）")

            Button {
                viewModel.refreshNow()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(viewModel.isRefreshing ? palette.activePinFill : palette.secondaryText)
                    .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                    .animation(
                        viewModel.isRefreshing
                            ? .linear(duration: 0.9).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isRefreshing
                    )
                    .frame(width: 24, height: 24)
                    .background(palette.pillFill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("立即刷新用量")
        }
    }

    private var pillTimeText: String {
        if viewModel.isRefreshing {
            return "同步中"
        }
        guard let fetchedAt = viewModel.snapshot?.fetchedAt else {
            return "未同步"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: fetchedAt)
    }

    private var statusDotColor: Color {
        if viewModel.errorMessage != nil {
            return palette.dangerAccent
        }
        if viewModel.isRefreshing {
            return palette.warningAccent
        }
        return palette.healthyDot
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text(message)
                .font(.system(size: 11))
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .foregroundStyle(palette.errorText)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(palette.errorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var loadingPlaceholder: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(viewModel.isRefreshing ? "正在获取 Google AI 实时配额..." : "暂无配额数据，点击右上角刷新")
                .font(.system(size: 12))
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(palette.subcardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(palette.subcardStroke, lineWidth: 0.75)
        )
    }
}

private struct GlassGroupSectionView: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let iconColor: Color
    let groupGradient: LinearGradient
    let group: ModelGroupSnapshot?
    let palette: GlassPalette
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.primaryText)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(palette.tertiaryText)

                Spacer()
            }

            if let group {
                GlassBucketRowView(
                    label: "5小时",
                    bucket: group.fiveHourBucket,
                    groupGradient: groupGradient,
                    palette: palette,
                    now: now
                )

                GlassBucketRowView(
                    label: "周配额",
                    bucket: group.weeklyBucket,
                    groupGradient: groupGradient,
                    palette: palette,
                    now: now
                )
            } else {
                Text("暂无该分组配额数据")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .padding(12)
        .background(palette.subcardFill)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(palette.subcardStroke, lineWidth: 0.75)
        )
    }
}

private struct GlassBucketRowView: View {
    let label: String
    let bucket: QuotaBucketSnapshot?
    let groupGradient: LinearGradient
    let palette: GlassPalette
    let now: Date

    private var fillGradient: LinearGradient {
        guard let bucket else { return groupGradient }
        if bucket.remainingPercentValue <= 15.0 {
            return palette.dangerBarGradient
        }
        if bucket.remainingPercentValue <= 30.0 {
            return palette.warningBarGradient
        }
        return groupGradient
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(label)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(palette.primaryText)

                if let bucket {
                    Text(bucket.resetCountdownText(now: now))
                        .font(.system(size: 10.5))
                        .foregroundStyle(palette.tertiaryText)
                        .lineLimit(1)
                        .monospacedDigit()
                }

                Spacer(minLength: 4)

                if let bucket {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("已用 \(bucket.usedText)")
                            .font(.system(size: 10.5))
                            .foregroundStyle(palette.secondaryText)

                        Text(bucket.remainingText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(palette.primaryText)
                    }
                    .monospacedDigit()
                } else {
                    Text("--")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(palette.secondaryText)
                }
            }

            CapsuleProgressBar(
                fraction: bucket?.remainingFraction ?? 0,
                fillGradient: fillGradient,
                trackColor: palette.barTrackFill
            )
            .frame(height: 8)
        }
    }
}

private struct CapsuleProgressBar: View {
    let fraction: Double
    let fillGradient: LinearGradient
    let trackColor: Color

    var body: some View {
        GeometryReader { geo in
            let totalWidth = max(0, geo.size.width)
            let clamped = min(max(fraction, 0.0), 1.0)
            let fillWidth = clamped <= 0.001 ? 0 : max(8, totalWidth * clamped)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)

                if fillWidth > 0 {
                    Capsule()
                        .fill(fillGradient)
                        .frame(width: min(totalWidth, fillWidth))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: clamped)
        }
    }
}
