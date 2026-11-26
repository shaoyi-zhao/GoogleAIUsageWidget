import Foundation

enum UsageServiceError: LocalizedError {
    case agyNotFound
    case executionFailed(String)
    case timedOut

    var errorDescription: String? {
        switch self {
        case .agyNotFound:
            return "未找到 agy 命令，请确认已安装 Antigravity CLI"
        case .executionFailed(let message):
            return message
        case .timedOut:
            return "查询超时，请检查网络或 agy 登录状态"
        }
    }
}

final class UsageService: Sendable {
    func fetchUsage() async throws -> UsageSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let snapshot = try self.fetchUsageSync()
                    continuation.resume(returning: snapshot)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func resolveAgyExecutable() -> (executable: String, prefixArgs: [String])? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.local/bin/agy",
            "/opt/homebrew/bin/agy",
            "/usr/local/bin/agy"
        ]
        for path in candidates where fileManager.isExecutableFile(atPath: path) {
            return (path, [])
        }
        return ("/usr/bin/env", ["agy"])
    }

    private func fetchUsageSync() throws -> UsageSnapshot {
        guard let target = resolveAgyExecutable() else {
            throw UsageServiceError.agyNotFound
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: target.executable)
        process.arguments = target.prefixArgs + [
            "-p", "/usage",
            "--output-format", "json",
            "--print-timeout", "25s"
        ]

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var env = ProcessInfo.processInfo.environment
        env["HOME"] = home
        let basePath = env["PATH"] ?? "/usr/bin:/bin"
        let extraPaths = "\(home)/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "\(extraPaths):\(basePath)"
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let finishSemaphore = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in
            finishSemaphore.signal()
        }

        do {
            try process.run()
        } catch {
            throw UsageServiceError.agyNotFound
        }

        let waitResult = finishSemaphore.wait(timeout: .now() + 30)
        if waitResult == .timedOut {
            if process.isRunning {
                process.terminate()
            }
            throw UsageServiceError.timedOut
        }

        let outData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdoutText = String(data: outData, encoding: .utf8) ?? ""
        let stderrText = String(data: errData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            let combined = (stderrText + "\n" + stdoutText).trimmingCharacters(in: .whitespacesAndNewlines)
            if combined.localizedCaseInsensitiveContains("sign in") ||
                combined.localizedCaseInsensitiveContains("Authentication required") {
                throw UsageServiceError.executionFailed("尚未登录 agy，请先在终端运行 agy 完成登录")
            }
            let summary = combined.isEmpty ? "agy 退出码 \(process.terminationStatus)" : String(combined.prefix(120))
            throw UsageServiceError.executionFailed(summary)
        }

        return try UsageParser.parse(rawOutput: stdoutText)
    }
}
