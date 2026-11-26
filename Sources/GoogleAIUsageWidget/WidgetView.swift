import SwiftUI

struct FlatPalette {
    let cardBackground: Color
    let sectionBackground: Color
    let border: Color
    let primaryText: Color
    let secondaryText: Color
    let trackBackground: Color
    let internalAccent: Color
    let externalAccent: Color
    let warningAccent: Color
    let dangerAccent: Color
    let errorBackground: Color
    let errorText: Color

    static func forScheme(_ scheme: ColorScheme) -> FlatPalette {
        if scheme == .dark {
            return FlatPalette(
                cardBackground: Color(hex: 0x14161A),
                sectionBackground: Color(hex: 0x1C1F26),
                border: Color(hex: 0x2A2F3A),
                primaryText: Color(hex: 0xF3F4F6),
                secondaryText: Color(hex: 0x9CA3AF),
                trackBackground: Color(hex: 0x2A2F3A),
                internalAccent: Color(hex: 0x3B82F6),
                externalAccent: Color(hex: 0x10B981),
                warningAccent: Color(hex: 0xF59E0B),
                dangerAccent: Color(hex: 0xEF4444),
                errorBackground: Color(hex: 0x3B181C),
                errorText: Color(hex: 0xFCA5A5)
            )
        } else {
            return FlatPalette(
                cardBackground: Color(hex: 0xFFFFFF),
                sectionBackground: Color(hex: 0xF5F6F8),
                border: Color(hex: 0xE2E6EC),
                primaryText: Color(hex: 0x111827),
                secondaryText: Color(hex: 0x6B7280),
                trackBackground: Color(hex: 0xE5E7EB),
                internalAccent: Color(hex: 0x2563EB),
                externalAccent: Color(hex: 0x059669),
                warningAccent: Color(hex: 0xD97706),
                dangerAccent: Color(hex: 0xDC2626),
                errorBackground: Color(hex: 0xFEF2F2),
                errorText: Color(hex: 0xB91C1C)
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
    @Environment(\.colorScheme) private var systemColorScheme

    private var effectiveColorScheme: ColorScheme {
        viewModel.appearanceMode.preferredColorScheme ?? systemColorScheme
    }

    private var palette: FlatPalette {
        FlatPalette.forScheme(effectiveColorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            headerBar

            if let errorMessage = viewModel.errorMessage {
                errorBanner(errorMessage)
            }

            if let snapshot = viewModel.snapshot {
                GroupSectionView(
                    title: "内部模型",
                    subtitle: "Gemini",
                    group: snapshot.internalGroup,
                    baseAccent: palette.internalAccent,
                    palette: palette,
                    now: viewModel.now
                )

                GroupSectionView(
                    title: "外部模型",
                    subtitle: "Claude / GPT",
                    group: snapshot.externalGroup,
                    baseAccent: palette.externalAccent,
                    palette: palette,
                    now: viewModel.now
                )
            } else {
                loadingPlaceholder
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(palette.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(palette.border, lineWidth: 1)
        )
        .environment(\.colorScheme, effectiveColorScheme)
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusDotColor)
                .frame(width: 7, height: 7)

            Text("Google AI 用量")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.primaryText)

            Spacer(minLength: 4)

            Text(viewModel.lastUpdatedText)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(palette.secondaryText)
                .monospacedDigit()

            Button {
                viewModel.isPinnedOnTop.toggle()
            } label: {
                Image(systemName: viewModel.isPinnedOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(viewModel.isPinnedOnTop ? palette.internalAccent : palette.secondaryText)
                    .frame(width: 22, height: 22)
                    .background(palette.sectionBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .help(viewModel.isPinnedOnTop ? "当前：始终置顶（点击切换贴附桌面）" : "当前：贴附桌面（点击切换始终置顶）")

            Button {
                viewModel.refreshNow()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(viewModel.isRefreshing ? palette.internalAccent : palette.secondaryText)
                    .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                    .animation(
                        viewModel.isRefreshing
                            ? .linear(duration: 0.9).repeatForever(autoreverses: false)
                            : .default,
                        value: viewModel.isRefreshing
                    )
                    .frame(width: 22, height: 22)
                    .background(palette.sectionBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("立即刷新用量")
        }
    }

    private var statusDotColor: Color {
        if viewModel.errorMessage != nil {
            return palette.dangerAccent
        }
        if viewModel.isRefreshing {
            return palette.warningAccent
        }
        return palette.externalAccent
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
        .padding(.vertical, 6)
        .background(palette.errorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var loadingPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.isRefreshing ? "正在从 Antigravity 获取实时配额..." : "暂无配额数据，点击右上角刷新")
                .font(.system(size: 12))
                .foregroundStyle(palette.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(palette.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct GroupSectionView: View {
    let title: String
    let subtitle: String
    let group: ModelGroupSnapshot?
    let baseAccent: Color
    let palette: FlatPalette
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(baseAccent)
                    .frame(width: 3, height: 12)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.primaryText)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(palette.secondaryText)

                Spacer()
            }

            if let group {
                BucketRowView(
                    label: "5小时",
                    bucket: group.fiveHourBucket,
                    baseAccent: baseAccent,
                    palette: palette,
                    now: now
                )

                BucketRowView(
                    label: "周配额",
                    bucket: group.weeklyBucket,
                    baseAccent: baseAccent,
                    palette: palette,
                    now: now
                )
            } else {
                Text("暂无该分组配额数据")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondaryText)
            }
        }
        .padding(10)
        .background(palette.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct BucketRowView: View {
    let label: String
    let bucket: QuotaBucketSnapshot?
    let baseAccent: Color
    let palette: FlatPalette
    let now: Date

    private var fillColor: Color {
        guard let bucket else { return palette.trackBackground }
        if bucket.remainingPercentValue <= 15.0 {
            return palette.dangerAccent
        }
        if bucket.remainingPercentValue <= 30.0 {
            return palette.warningAccent
        }
        return baseAccent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(palette.primaryText)

                Spacer()

                if let bucket {
                    HStack(spacing: 6) {
                        Text("已用 \(bucket.usedText)")
                            .foregroundStyle(palette.secondaryText)
                        Text("·")
                            .foregroundStyle(palette.secondaryText)
                        Text("剩余 \(bucket.remainingText)")
                            .fontWeight(.semibold)
                            .foregroundStyle(palette.primaryText)
                    }
                    .font(.system(size: 11))
                    .monospacedDigit()
                } else {
                    Text("--")
                        .font(.system(size: 11))
                        .foregroundStyle(palette.secondaryText)
                }
            }

            GeometryReader { geo in
                let fraction = bucket?.remainingFraction ?? 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(palette.trackBackground)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(fillColor)
                        .frame(width: max(0, geo.size.width * fraction))
                }
            }
            .frame(height: 6)

            if let bucket {
                Text(bucket.resetCountdownText(now: now))
                    .font(.system(size: 10))
                    .foregroundStyle(palette.secondaryText)
                    .monospacedDigit()
            }
        }
    }
}
