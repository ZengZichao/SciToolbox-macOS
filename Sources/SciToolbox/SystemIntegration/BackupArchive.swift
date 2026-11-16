import Foundation

// MARK: - BackupArchive（H1：备份归档模型）

/// 全量备份归档——收藏 + 历史 + 集合 + 结果集 + 设置子集。
/// 用于 NSSavePanel 导出 / NSOpenPanel 恢复。
/// CodingKeys 与 encode/decode 在 SystemIntegration.swift 中手动实现（含 iso8601 日期）。
struct BackupArchive: Codable {
    var schemaVersion: Int = 1
    var exportedAt: Date
    var favorites: [FavoriteItem]
    var history: [HistoryEntry]
    var collections: [SciCollection]
    var resultSets: [ResultSet]
    /// 已知 UserDefaults 键白名单导出（仅非敏感偏好设置）。
    var settings: [String: String]

    @MainActor
    init() {
        self.exportedAt = Date()
        self.favorites = LocalFavorites.shared.favorites
        self.history = SearchHistory.shared.entries
        self.collections = CollectionStore.shared.collections
        self.resultSets = ResultSetStore.shared.resultSets
        self.settings = BackupArchive.exportSettings()
    }

    init(favorites: [FavoriteItem], history: [HistoryEntry], collections: [SciCollection],
         resultSets: [ResultSet], settings: [String: String], exportedAt: Date = Date()) {
        self.exportedAt = exportedAt
        self.favorites = favorites
        self.history = history
        self.collections = collections
        self.resultSets = resultSets
        self.settings = settings
    }

    /// 导出当前已知安全设置键。
    private static func exportSettings() -> [String: String] {
        let keys = ["appearance", "sidebarDensity", "cacheEnabled", "appLanguage", "sidebarVisible", "hasSeenOnboarding", "onboardingDone"]
        var dict: [String: String] = [:]
        for key in keys {
            if let val = UserDefaults.standard.string(forKey: key) {
                dict[key] = val
            }
        }
        // Bool 型设置单独处理
        for boolKey in ["cacheEnabled", "sidebarVisible", "onboardingDone"] {
            if dict[boolKey] == nil {
                dict[boolKey] = UserDefaults.standard.bool(forKey: boolKey) ? "true" : "false"
            }
        }
        return dict
    }
}
