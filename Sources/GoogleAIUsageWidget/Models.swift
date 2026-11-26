import Foundation

// MARK: - CLI JSON 原始数据结构

struct AgyUsageResponse: Decodable {
    let status: String?
    let command: CommandPayload?

    struct CommandPayload: Decodable {
        let name: String?
        let data: UsageData?
    }

    struct UsageData: Decodable {
        let description: String?
        let groups: [UsageGroupRaw]
    }

    struct UsageGroupRaw: Decodable {
        let name: String
        let description: String?
        let buckets: [UsageBucketRaw]
    }

    struct UsageBucketRaw: Decodable {
        let id: String
        let name: String?
        let description: String?
        let window: String
        let remainingFraction: Double
        let resetTime: String?

        enum CodingKeys: String, CodingKey {
            case id
            case name
            case description
            case window
            case remainingFraction = "remaining_fraction"
            case resetTime = "reset_time"
        }
    }
}

// MARK: - UI 展示模型

enum ModelCategory: String, Sendable {
    case internalGemini
    case externalThirdParty

    var title: String {
        switch self {
        case .internalGemini: return "内部模型"
        case .externalThirdParty: return "外部模型"
        }
    }

    var subtitle: String {
        switch self {
        case .internalGemini: return "Gemini"
        case .externalThirdParty: return "Claude / GPT"
        }
    }
}

struct QuotaBucketSnapshot: Identifiable, Sendable, Equatable {
    let id: String
    let windowType: String       // "5h" or "weekly"
    let windowTitle: String      // "5小时" or "周配额"
    let remainingFraction: Double
    let remainingPercentValue: Double
    let usedPercentValue: Double
    let resetDate: Date?

    var remainingText: String {
        Self.formatPercent(remainingPercentValue)
    }

    var usedText: String {
        Self.formatPercent(usedPercentValue)
    }

    func resetCountdownText(now: Date = Date()) -> String {
        guard let resetDate else {
            return "满额 · 未开始计时"
        }
        let year = Calendar(identifier: .gregorian).component(.year, from: resetDate)
        if year <= 1971 {
            return "满额 · 未开始计时"
        }
        let delta = resetDate.timeIntervalSince(now)
        if delta <= 0 {
            return "即将刷新"
        }
        let totalMinutes = Int(ceil(delta / 60.0))
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60

        if days >= 1 {
            return "\(days)天\(hours)小时后重置"
        } else if hours >= 1 {
            return "\(hours)小时\(minutes)分后重置"
        } else {
            return "\(max(1, minutes))分钟后重置"
        }
    }

    static func formatPercent(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if abs(rounded - rounded.rounded()) < 0.05 {
            return "\(Int(rounded.rounded()))%"
        }
        return String(format: "%.1f%%", rounded)
    }
}

struct ModelGroupSnapshot: Identifiable, Sendable, Equatable {
    let id: String
    let category: ModelCategory
    let fiveHourBucket: QuotaBucketSnapshot?
    let weeklyBucket: QuotaBucketSnapshot?
}

struct UsageSnapshot: Sendable, Equatable {
    let fetchedAt: Date
    let internalGroup: ModelGroupSnapshot?
    let externalGroup: ModelGroupSnapshot?
}

enum UsageParserError: LocalizedError, Equatable {
    case emptyOutput
    case invalidJSON
    case missingUsageData
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyOutput:
            return "未收到 agy 输出"
        case .invalidJSON:
            return "无法解析 agy 返回的 JSON 数据"
        case .missingUsageData:
            return "返回结果中缺少配额数据"
        case .commandFailed(let message):
            return message
        }
    }
}

// MARK: - 解析器

enum UsageParser {
    static func extractJSONData(from rawOutput: String) -> Data? {
        guard let start = rawOutput.firstIndex(of: "{"),
              let end = rawOutput.lastIndex(of: "}"),
              start <= end else {
            return nil
        }
        let slice = String(rawOutput[start...end])
        return slice.data(using: .utf8)
    }

    static func parse(rawOutput: String, now: Date = Date()) throws -> UsageSnapshot {
        let trimmed = rawOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw UsageParserError.emptyOutput
        }
        guard let jsonData = extractJSONData(from: trimmed) else {
            throw UsageParserError.invalidJSON
        }
        let decoded: AgyUsageResponse
        do {
            decoded = try JSONDecoder().decode(AgyUsageResponse.self, from: jsonData)
        } catch {
            throw UsageParserError.invalidJSON
        }

        if let status = decoded.status, status.uppercased() != "SUCCESS" {
            throw UsageParserError.commandFailed("agy 返回状态异常: \(status)")
        }

        guard let groups = decoded.command?.data?.groups, !groups.isEmpty else {
            throw UsageParserError.missingUsageData
        }

        var internalGroup: ModelGroupSnapshot?
        var externalGroup: ModelGroupSnapshot?

        for rawGroup in groups {
            let category = classifyGroup(rawGroup)
            let buckets = rawGroup.buckets.map(makeBucketSnapshot)
            let fiveHour = buckets.first { $0.windowType == "5h" || $0.id.hasSuffix("-5h") }
            let weekly = buckets.first { $0.windowType == "weekly" || $0.id.hasSuffix("-weekly") }

            let snapshot = ModelGroupSnapshot(
                id: category.rawValue,
                category: category,
                fiveHourBucket: fiveHour,
                weeklyBucket: weekly
            )

            switch category {
            case .internalGemini:
                internalGroup = snapshot
            case .externalThirdParty:
                externalGroup = snapshot
            }
        }

        guard internalGroup != nil || externalGroup != nil else {
            throw UsageParserError.missingUsageData
        }

        return UsageSnapshot(
            fetchedAt: now,
            internalGroup: internalGroup,
            externalGroup: externalGroup
        )
    }

    private static func classifyGroup(_ group: AgyUsageResponse.UsageGroupRaw) -> ModelCategory {
        let lowerName = group.name.lowercased()
        let hasGeminiBucket = group.buckets.contains { $0.id.lowercased().hasPrefix("gemini-") }
        let hasThirdPartyBucket = group.buckets.contains { $0.id.lowercased().hasPrefix("3p-") }

        if hasGeminiBucket || lowerName.contains("gemini") {
            return .internalGemini
        }
        if hasThirdPartyBucket || lowerName.contains("claude") || lowerName.contains("gpt") {
            return .externalThirdParty
        }
        return .externalThirdParty
    }

    private static func makeBucketSnapshot(_ raw: AgyUsageResponse.UsageBucketRaw) -> QuotaBucketSnapshot {
        let clamped = min(max(raw.remainingFraction, 0.0), 1.0)
        let remainingPct = (clamped * 1000.0).rounded() / 10.0
        let usedPct = ((100.0 - remainingPct) * 10.0).rounded() / 10.0
        let windowType = raw.window.lowercased()
        let title: String
        if windowType == "5h" || raw.id.lowercased().hasSuffix("-5h") {
            title = "5小时"
        } else if windowType == "weekly" || raw.id.lowercased().hasSuffix("-weekly") {
            title = "周配额"
        } else {
            title = raw.name ?? raw.window
        }

        return QuotaBucketSnapshot(
            id: raw.id,
            windowType: windowType,
            windowTitle: title,
            remainingFraction: clamped,
            remainingPercentValue: remainingPct,
            usedPercentValue: usedPct,
            resetDate: parseISO8601(raw.resetTime)
        )
    }

    static func parseISO8601(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractionalFormatter.date(from: string) {
            return date
        }
        let standardFormatter = ISO8601DateFormatter()
        standardFormatter.formatOptions = [.withInternetDateTime]
        return standardFormatter.date(from: string)
    }
}
