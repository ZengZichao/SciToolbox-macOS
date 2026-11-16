import Foundation
import SQLite3

// MARK: - SQLiteStore（SQLite3 封装）

/// SQLite3 系统库封装——提供基础数据库操作，供 LocalSearchIndex 使用。
/// 数据库文件位于 `Application Support/SciToolbox/search.db`。
final class SQLiteStore {
    private var db: OpaquePointer?
    private let dbPath: String

    static let shared = SQLiteStore()

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let scitoolboxDir = appSupport.appendingPathComponent("SciToolbox", isDirectory: true)
        try? FileManager.default.createDirectory(at: scitoolboxDir, withIntermediateDirectories: true)
        dbPath = scitoolboxDir.appendingPathComponent("search.db").path

        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            // 启用 WAL 模式提升并发读写
            exec("PRAGMA journal_mode=WAL;")
            createFTSTable()
        }
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - FTS5 Table

    private func createFTSTable() {
        let sql = """
        CREATE VIRTUAL TABLE IF NOT EXISTS item_fts USING fts5(
            kind TEXT UNINDEXED,
            tool_id TEXT UNINDEXED,
            item_id TEXT UNINDEXED,
            title TEXT,
            body TEXT,
            note TEXT,
            tokenize='unicode61'
        );
        """
        exec(sql)
    }

    // MARK: - Operations

    func exec(_ sql: String) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return false }
        defer { sqlite3_finalize(stmt) }
        return sqlite3_step(stmt) == SQLITE_DONE
    }

    func upsert(kind: String, toolId: String, itemId: String, title: String, body: String, note: String?) {
        // 先删除同 kind+item_id 的旧记录
        var delStmt: OpaquePointer?
        let delSql = "DELETE FROM item_fts WHERE kind=? AND item_id=?;"
        if sqlite3_prepare_v2(db, delSql, -1, &delStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(delStmt, 1, kind, -1, nil)
            sqlite3_bind_text(delStmt, 2, itemId, -1, nil)
            sqlite3_step(delStmt)
            sqlite3_finalize(delStmt)
        }

        // 插入新记录
        var insStmt: OpaquePointer?
        let insSql = "INSERT INTO item_fts(kind, tool_id, item_id, title, body, note) VALUES(?,?,?,?,?,?);"
        if sqlite3_prepare_v2(db, insSql, -1, &insStmt, nil) == SQLITE_OK {
            sqlite3_bind_text(insStmt, 1, kind, -1, nil)
            sqlite3_bind_text(insStmt, 2, toolId, -1, nil)
            sqlite3_bind_text(insStmt, 3, itemId, -1, nil)
            sqlite3_bind_text(insStmt, 4, title, -1, nil)
            sqlite3_bind_text(insStmt, 5, body, -1, nil)
            if let note = note {
                sqlite3_bind_text(insStmt, 6, note, -1, nil)
            } else {
                sqlite3_bind_null(insStmt, 6)
            }
            sqlite3_step(insStmt)
            sqlite3_finalize(insStmt)
        }
    }

    func remove(kind: String, itemId: String) {
        var stmt: OpaquePointer?
        let sql = "DELETE FROM item_fts WHERE kind=? AND item_id=?;"
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, kind, -1, nil)
            sqlite3_bind_text(stmt, 2, itemId, -1, nil)
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }

    func removeAll(kind: String? = nil) {
        if let kind {
            exec("DELETE FROM item_fts WHERE kind='\(kind)';")
        } else {
            exec("DELETE FROM item_fts;")
        }
    }

    func query(_ text: String, limit: Int = 50) -> [LocalSearchIndex.LocalHit] {
        // FTS5 全文搜索——对搜索词做前缀匹配
        let escaped = text
            .replacingOccurrences(of: "\"", with: "\"\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !escaped.isEmpty else { return [] }

        // 构造 FTS5 MATCH 查询：标题和正文都搜
        let matchExpr = "\"\(escaped)\"*"
        let sql = """
        SELECT kind, tool_id, item_id, title, snippet(item_fts, 4, '«', '»', '…', 16) as snippet
        FROM item_fts
        WHERE item_fts MATCH '\(matchExpr)'
        ORDER BY rank
        LIMIT \(limit);
        """

        var stmt: OpaquePointer?
        var results: [LocalSearchIndex.LocalHit] = []

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let kind = stringColumn(stmt, 0)
            let toolId = stringColumn(stmt, 1)
            let itemId = stringColumn(stmt, 2)
            let title = stringColumn(stmt, 3)
            let snippet = stringColumn(stmt, 4)
            results.append(LocalSearchIndex.LocalHit(
                kind: kind, toolId: toolId, itemId: itemId,
                title: title, snippet: snippet
            ))
        }

        return results
    }

    func count() -> Int {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM item_fts;", -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
    }

    private func stringColumn(_ stmt: OpaquePointer?, _ index: Int32) -> String {
        if let cString = sqlite3_column_text(stmt, index) {
            return String(cString: cString)
        }
        return ""
    }
}

// MARK: - LocalSearchIndex（B2：本地全文搜索索引）

/// 本地全文搜索索引——基于 SQLite FTS5。
/// 索引范围：收藏、集合条目、结果集。
/// 写操作由各 Store 的增删改触发；查询供搜索 UI 调用。
@MainActor
final class LocalSearchIndex: ObservableObject {
    static let shared = LocalSearchIndex()

    struct LocalHit: Identifiable {
        let kind: String
        let toolId: String
        let itemId: String
        let title: String
        let snippet: String

        var id: String { "\(kind)-\(itemId)" }
    }

    private let store = SQLiteStore.shared
    @Published var hitCount: Int = 0

    private init() {
        hitCount = store.count()
    }

    // MARK: - Index operations

    /// 索引/更新收藏条目
    func indexFavorite(_ fav: FavoriteItem) {
        let body = fav.snapshot?.values.joined(separator: " ") ?? fav.subtitle ?? ""
        store.upsert(kind: "favorite", toolId: fav.toolId, itemId: fav.itemId,
                      title: fav.title, body: body, note: fav.note)
        hitCount = store.count()
    }

    /// 删除收藏索引
    func removeFavorite(itemId: String) {
        store.remove(kind: "favorite", itemId: itemId)
        hitCount = store.count()
    }

    /// 索引集合条目
    func indexCollectionEntry(_ entry: CollectionEntry, collectionName: String) {
        store.upsert(kind: "collection", toolId: entry.toolId, itemId: entry.itemId,
                      title: entry.title, body: "\(collectionName) · \(entry.toolName)", note: nil)
        hitCount = store.count()
    }

    /// 删除集合条目索引
    func removeCollectionEntry(itemId: String) {
        store.remove(kind: "collection", itemId: itemId)
        hitCount = store.count()
    }

    /// 索引结果集
    func indexResultSet(_ set: ResultSet) {
        for item in set.items {
            store.upsert(kind: "resultset", toolId: item.toolId, itemId: item.itemId,
                          title: item.title, body: item.subtitle ?? set.name,
                          note: set.note)
        }
        hitCount = store.count()
    }

    /// 删除结果集索引
    func removeResultSet(id: String) {
        store.remove(kind: "resultset", itemId: id)
        hitCount = store.count()
    }

    /// 重建全部索引（首启预热 / 恢复后调用）
    func rebuildAll(favorites: [FavoriteItem], collections: [SciCollection], resultSets: [ResultSet]) {
        store.removeAll()

        for fav in favorites {
            indexFavorite(fav)
        }
        for col in collections {
            for entry in col.entries {
                indexCollectionEntry(entry, collectionName: col.name)
            }
        }
        for set in resultSets {
            indexResultSet(set)
        }
    }

    /// 清空索引
    func clearAll() {
        store.removeAll()
        hitCount = 0
    }

    /// 全文搜索
    func query(_ text: String, limit: Int = 50) -> [LocalHit] {
        store.query(text, limit: limit)
    }
}
