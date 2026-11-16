import SwiftUI
import AppKit
import CoreSpotlight
import UniformTypeIdentifiers

// MARK: - AppStoreIntegrationModifier

/// App Store 改造：系统集成通知路由 modifier。
/// 将 Dock 菜单 / URL Scheme / Services 触发的通知统一路由到 ContentView 的动作。
struct AppStoreIntegrationModifier: ViewModifier {
    let onOpenLocalTool: () -> Void
    let onOpenMyFiles: () -> Void
    let onSmartIdentify: (String) -> Void

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .openLocalTool)) { _ in
                onOpenLocalTool()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openMyFiles)) { note in
                onOpenMyFiles()
                if let url = note.userInfo?["url"] as? URL {
                    ImportedDataStore.shared.importFile(url: url)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .smartIdentifyText)) { note in
                if let text = note.userInfo?["text"] as? String {
                    onSmartIdentify(text)
                }
            }
            .onOpenURL { url in
                URLSchemeRouter.shared.handle(url)
            }
    }
}

// MARK: - URLSchemeRouter (G3)

/// URL Scheme 路由器：解析 `scitoolbox://` 链接并分发到对应通知。
@MainActor
final class URLSchemeRouter {
    static let shared = URLSchemeRouter()

    enum Route {
        case search(toolId: String, query: String)
        case identify(text: String)
        case openFile(url: URL)
        case openLocalTools
        case openMyFiles
        case unknown
    }

    func parse(_ url: URL) -> Route {
        guard url.scheme == "scitoolbox" else { return .unknown }
        let action = url.host ?? ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        switch action {
        case "search":
            let toolId = queryItems.first(where: { $0.name == "tool" })?.value ?? ""
            let q = queryItems.first(where: { $0.name == "q" })?.value ?? ""
            guard !toolId.isEmpty, !q.isEmpty else { return .unknown }
            return .search(toolId: toolId, query: q)
        case "identify":
            let text = queryItems.first(where: { $0.name == "text" })?.value ?? ""
            guard !text.isEmpty else { return .unknown }
            return .identify(text: text)
        case "open":
            if let fileStr = queryItems.first(where: { $0.name == "file" })?.value,
               let fileURL = URL(string: fileStr) {
                return .openFile(url: fileURL)
            }
            return .unknown
        case "localtools":
            return .openLocalTools
        case "myfiles":
            return .openMyFiles
        default:
            return .unknown
        }
    }

    func handle(_ url: URL) {
        switch parse(url) {
        case .search(let toolId, let query):
            NotificationCenter.default.post(
                name: .navigateToTool,
                object: nil,
                userInfo: ["toolId": toolId, "query": query, "autoDetail": true]
            )
        case .identify(let text):
            NotificationCenter.default.post(
                name: .smartIdentifyText,
                object: nil,
                userInfo: ["text": text]
            )
        case .openFile(let fileURL):
            NotificationCenter.default.post(
                name: .openMyFiles,
                object: nil,
                userInfo: ["url": fileURL]
            )
        case .openLocalTools:
            NotificationCenter.default.post(name: .openLocalTool, object: nil)
        case .openMyFiles:
            NotificationCenter.default.post(name: .openMyFiles, object: nil)
        case .unknown:
            break
        }
    }
}

// MARK: - ClipboardMonitor (D1：剪贴板智能识别，默认关闭)

/// 剪贴板智能识别——监听 NSPasteboard 变化，命中 AccessionRouter 时提示用户。
/// 仅在设置开关打开且应用为激活态时处理。无隐私收集。
@MainActor
final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()

    @Published var isEnabled = false
    @Published var detectedText: String?

    private var timer: Timer?
    private var lastChangeCount: Int = 0

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: "clipboardMonitorEnabled")
        lastChangeCount = NSPasteboard.general.changeCount
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "clipboardMonitorEnabled")
        if enabled {
            start()
        } else {
            stop()
        }
    }

    func start() {
        guard isEnabled else { return }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkClipboard() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        guard isEnabled,
              NSApp.isActive,
              NSPasteboard.general.changeCount != lastChangeCount else { return }

        lastChangeCount = NSPasteboard.general.changeCount

        guard let text = NSPasteboard.general.string(forType: .string),
              !text.isEmpty,
              text.count < 200 else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = AccessionRouter.classify(trimmed)
        guard !matches.isEmpty else { return }

        detectedText = trimmed
        Clipboard.showToast(DT.t("识别到：\(trimmed)", "Detected: \(trimmed)"))
    }
}

// MARK: - SpotlightIndexer (D3：Spotlight 索引)

/// Spotlight 索引器——将收藏/集合条目索引到 Core Spotlight，仅本机索引。
@MainActor
final class SpotlightIndexer: ObservableObject {
    static let shared = SpotlightIndexer()

    @Published var indexedCount: Int = 0

    private init() {}

    /// 索引收藏条目
    func indexFavorites(_ favorites: [FavoriteItem]) {
        let items = favorites.map { fav -> CSSearchableItem in
            let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
            attributeSet.title = fav.title
            attributeSet.contentDescription = fav.subtitle ?? fav.toolName
            attributeSet.keywords = [fav.toolName, fav.itemId]
            let item = CSSearchableItem(
                uniqueIdentifier: "favorite-\(fav.id)",
                domainIdentifier: "SciToolbox.favorites",
                attributeSet: attributeSet
            )
            return item
        }

        CSSearchableIndex.default().indexSearchableItems(items) { [weak self] _ in
            Task { @MainActor in
                self?.indexedCount = items.count
            }
        }
    }

    /// 索引集合条目
    func indexCollections(_ collections: [SciCollection]) {
        var items: [CSSearchableItem] = []
        for col in collections {
            for entry in col.entries {
                let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
                attributeSet.title = entry.title
                attributeSet.contentDescription = "\(col.name) · \(entry.toolName)"
                attributeSet.keywords = [entry.itemId, col.name]
                let item = CSSearchableItem(
                    uniqueIdentifier: "collection-\(entry.id)",
                    domainIdentifier: "SciToolbox.collections",
                    attributeSet: attributeSet
                )
                items.append(item)
            }
        }

        CSSearchableIndex.default().indexSearchableItems(items) { [weak self] _ in
            Task { @MainActor in
                self?.indexedCount += items.count
            }
        }
    }

    /// 删除指定收藏的索引
    func deleteFavorite(id: String) {
        CSSearchableIndex.default().deleteSearchableItems(
            withIdentifiers: ["favorite-\(id)"]
        ) { _ in }
    }

    /// 清空所有索引
    func clearAll() {
        CSSearchableIndex.default().deleteAllSearchableItems { _ in }
        indexedCount = 0
    }
}

// MARK: - BackupManager (H1：备份/恢复管理器)

/// 备份/恢复管理器——导出全量数据为 JSON 文件，从文件恢复。
@MainActor
final class BackupManager: ObservableObject {
    static let shared = BackupManager()

    /// 导出全量备份到 NSSavePanel
    @discardableResult
    func exportArchive() -> Bool {
        let archive = BackupArchive()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(archive) else {
            Clipboard.showToast(L10n.t(.exportFailed2))
            return false
        }

        let panel = NSSavePanel()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateStr = dateFormatter.string(from: Date())
        panel.nameFieldStringValue = "SciToolboxBackup-\(dateStr).json"
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else { return false }

        do {
            try data.write(to: url)
            Clipboard.showToast(L10n.t(.allDataExported))
            return true
        } catch {
            Clipboard.showToast(L10n.t(.exportFailed2))
            return false
        }
    }

    /// 从备份文件恢复
    func restoreFromBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let data = try? Data(contentsOf: url) else {
            Clipboard.showToast(L10n.t(.exportFailed2))
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let archive = try? decoder.decode(BackupArchive.self, from: data) else {
            Clipboard.showToast(L10n.t(.exportFailed2))
            return
        }

        // 恢复各 Store
        LocalFavorites.shared.restoreAll(archive.favorites)
        SearchHistory.shared.restoreAll(archive.history)
        CollectionStore.shared.restoreAll(archive.collections)
        ResultSetStore.shared.restoreAll(archive.resultSets)

        // 恢复设置
        for (key, value) in archive.settings {
            UserDefaults.standard.set(value, forKey: key)
        }

        Clipboard.showToast(DT.t("恢复成功，请重启应用生效", "Restore successful, please restart the app"))
    }
}

// MARK: - BackupArchive date encoding support

extension BackupArchive {
    enum CodingKeys: String, CodingKey {
        case schemaVersion, exportedAt, favorites, history, collections, resultSets, settings
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        exportedAt = try c.decode(Date.self, forKey: .exportedAt)
        favorites = try c.decode([FavoriteItem].self, forKey: .favorites)
        history = try c.decode([HistoryEntry].self, forKey: .history)
        collections = try c.decode([SciCollection].self, forKey: .collections)
        resultSets = try c.decode([ResultSet].self, forKey: .resultSets)
        settings = try c.decode([String: String].self, forKey: .settings)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(schemaVersion, forKey: .schemaVersion)
        try c.encode(exportedAt, forKey: .exportedAt)
        try c.encode(favorites, forKey: .favorites)
        try c.encode(history, forKey: .history)
        try c.encode(collections, forKey: .collections)
        try c.encode(resultSets, forKey: .resultSets)
        try c.encode(settings, forKey: .settings)
    }
}
