import Foundation
import XCTest
@testable import GoogleAIUsageWidget

final class UsageParserTests: XCTestCase {
    func testParseRealAgyOutput() throws {
        let sampleJSON = """
        {"conversation_id":"","status":"SUCCESS","response":"...","duration_seconds":0,"num_turns":0,"command":{"name":"usage","data":{"description":"test","groups":[{"name":"Gemini Models","description":"Gemini","buckets":[{"id":"gemini-weekly","name":"Weekly Limit Remaining","window":"weekly","remaining_fraction":0.989983320236206,"reset_time":"2026-12-03T03:41:11Z"},{"id":"gemini-5h","name":"Five Hour Limit Remaining","window":"5h","remaining_fraction":0.9799333214759827,"reset_time":"2026-11-26T08:41:11Z"}]},{"name":"Claude and GPT models","description":"3P","buckets":[{"id":"3p-weekly","name":"Weekly Limit Remaining","window":"weekly","remaining_fraction":1,"reset_time":"1970-01-01T00:00:00Z"},{"id":"3p-5h","name":"Five Hour Limit Remaining","window":"5h","remaining_fraction":1,"reset_time":"1970-01-01T00:00:00Z"}]}]}}}
        """

        let fixedNow = UsageParser.parseISO8601("2026-11-26T03:41:11Z")!
        let snapshot = try UsageParser.parse(rawOutput: sampleJSON, now: fixedNow)

        let internalGroup = try XCTUnwrap(snapshot.internalGroup)
        XCTAssertEqual(internalGroup.category, .internalGemini)
        let gemini5h = try XCTUnwrap(internalGroup.fiveHourBucket)
        let geminiWeekly = try XCTUnwrap(internalGroup.weeklyBucket)

        XCTAssertEqual(gemini5h.windowTitle, "5小时")
        XCTAssertEqual(gemini5h.remainingPercentValue, 98.0, accuracy: 0.001)
        XCTAssertEqual(gemini5h.usedPercentValue, 2.0, accuracy: 0.001)
        XCTAssertEqual(gemini5h.remainingText, "98%")
        XCTAssertEqual(gemini5h.usedText, "2%")
        XCTAssertEqual(gemini5h.resetCountdownText(now: fixedNow), "5小时0分后重置")

        XCTAssertEqual(geminiWeekly.windowTitle, "周配额")
        XCTAssertEqual(geminiWeekly.remainingPercentValue, 99.0, accuracy: 0.001)
        XCTAssertEqual(geminiWeekly.usedPercentValue, 1.0, accuracy: 0.001)
        XCTAssertEqual(geminiWeekly.resetCountdownText(now: fixedNow), "7天0小时后重置")

        let externalGroup = try XCTUnwrap(snapshot.externalGroup)
        XCTAssertEqual(externalGroup.category, .externalThirdParty)
        let ext5h = try XCTUnwrap(externalGroup.fiveHourBucket)
        let extWeekly = try XCTUnwrap(externalGroup.weeklyBucket)

        XCTAssertEqual(ext5h.remainingText, "100%")
        XCTAssertEqual(ext5h.usedText, "0%")
        XCTAssertEqual(ext5h.resetCountdownText(now: fixedNow), "满额 · 未开始计时")
        XCTAssertEqual(extWeekly.resetCountdownText(now: fixedNow), "满额 · 未开始计时")
    }

    func testComplementaryPercentagesWithDecimals() throws {
        let json = """
        {"status":"SUCCESS","command":{"name":"usage","data":{"groups":[{"name":"Gemini Models","buckets":[{"id":"gemini-5h","window":"5h","remaining_fraction":0.8734,"reset_time":"2026-11-26T06:00:00Z"}]}]}}}
        """
        let snapshot = try UsageParser.parse(rawOutput: json)
        let bucket = try XCTUnwrap(snapshot.internalGroup?.fiveHourBucket)

        XCTAssertEqual(bucket.remainingPercentValue, 87.3, accuracy: 0.001)
        XCTAssertEqual(bucket.usedPercentValue, 12.7, accuracy: 0.001)
        XCTAssertEqual(bucket.remainingText, "87.3%")
        XCTAssertEqual(bucket.usedText, "12.7%")
        XCTAssertEqual(bucket.remainingPercentValue + bucket.usedPercentValue, 100.0, accuracy: 0.001)
    }

    func testCountdownLessThanOneHourAndExpired() throws {
        let now = UsageParser.parseISO8601("2026-11-26T08:00:00Z")!
        let json = """
        {"status":"SUCCESS","command":{"name":"usage","data":{"groups":[{"name":"Gemini Models","buckets":[{"id":"gemini-5h","window":"5h","remaining_fraction":0.5,"reset_time":"2026-11-26T08:42:00Z"},{"id":"gemini-weekly","window":"weekly","remaining_fraction":0.2,"reset_time":"2026-11-26T07:50:00Z"}]}]}}}
        """
        let snapshot = try UsageParser.parse(rawOutput: json, now: now)
        let fiveH = try XCTUnwrap(snapshot.internalGroup?.fiveHourBucket)
        let weekly = try XCTUnwrap(snapshot.internalGroup?.weeklyBucket)

        XCTAssertEqual(fiveH.resetCountdownText(now: now), "42分钟后重置")
        XCTAssertEqual(weekly.resetCountdownText(now: now), "即将刷新")
    }

    func testParseHandlesLeadingLogNoise() throws {
        let noisy = """
        Fetching usage...
        {"status":"SUCCESS","command":{"name":"usage","data":{"groups":[{"name":"Claude and GPT models","buckets":[{"id":"3p-5h","window":"5h","remaining_fraction":0.64,"reset_time":"1970-01-01T00:00:00Z"}]}]}}}
        """
        let snapshot = try UsageParser.parse(rawOutput: noisy)
        let bucket = try XCTUnwrap(snapshot.externalGroup?.fiveHourBucket)
        XCTAssertEqual(bucket.remainingText, "64%")
        XCTAssertEqual(bucket.usedText, "36%")
    }
}
