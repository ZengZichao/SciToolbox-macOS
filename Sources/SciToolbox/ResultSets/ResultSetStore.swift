import Foundation

// MARK: - ResultSet（F1/F2：结果集数据模型）

/// 检索结果集——将搜索结果保存为可命名的本地数据集，支持集合运算。
struct ResultSetItem: Identifiable, Codable, Hashable {
    let id: String         // UUID
    let toolId: String
    let toolName: String
    let itemId: String
    let title: String
    let subtitle: String?
    let context: [String: String]?

    init(toolId: String, toolName: String, itemId: String, title: String,
         subtitle: String? = nil, context: [String: String]? = nil) {
        self.id = UUID().uuidString
        self.toolId = toolId
        self.toolName = toolName
        self.itemId = itemId
        self.title = title
        self.subtitle = subtitle
        self.context = context
    }

    /// 从 `ResultItem` + Provider 构造。
    init(from item: ResultItem, toolId: String, toolName: String) {
        self.id = UUID().uuidString
        self.toolId = toolId
        self.toolName = toolName
        self.itemId = item.id
        self.title = item.title
        self.subtitle = item.subtitle
        self.context = item.extra
    }
}

struct ResultSet: Identifiable, Codable, Hashable {
    let id: String         // UUID
    var name: String
    var note: String?
    var tags: [String]
    var items: [ResultSetItem]
    let createdAt: Date
    var updatedAt: Date

    init(name: String, note: String? = nil, tags: [String] = [], items: [ResultSetItem] = []) {
        self.id = UUID().uuidString
        self.name = name
        self.note = note
        self.tags = tags
        self.items = items
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - SetOps（F2：集合运算）

/// 结果集集合运算——纯函数，基于去重键 (accession/itemId.lowercased, toolId)。
enum SetOps {

    /// 去重键：优先使用 accession（context["accession"]），否则 itemId，全部小写归一。
    static func dedupKey(_ item: ResultSetItem) -> String {
        let accession = item.context?["accession"] ?? item.itemId
        return "\(accession.lowercased())@\(item.toolId)"
    }

    /// 去重——保留首次出现的条目。
    static func dedup(_ items: [ResultSetItem]) -> [ResultSetItem] {
        var seen = Set<String>()
        return items.filter { seen.insert(dedupKey($0)).inserted }
    }

    /// 并集（去重）。
    static func union(_ a: [ResultSetItem], _ b: [ResultSetItem]) -> [ResultSetItem] {
        dedup(a + b)
    }

    /// 交集——同时出现在 a 和 b 中的条目（以去重键匹配）。
    static func intersect(_ a: [ResultSetItem], _ b: [ResultSetItem]) -> [ResultSetItem] {
        let bKeys = Set(b.map { dedupKey($0) })
        return dedup(a.filter { bKeys.contains(dedupKey($0)) })
    }

    /// 差集——在 a 中但不在 b 中的条目。
    static func subtract(_ a: [ResultSetItem], _ b: [ResultSetItem]) -> [ResultSetItem] {
        let bKeys = Set(b.map { dedupKey($0) })
        return dedup(a.filter { !bKeys.contains(dedupKey($0)) })
    }
}

// MARK: - ResultSetStore（持久化）

/// 结果集持久化管理器。
/// 存储范式：`UserDefaults` key `SciToolbox.ResultSets`（与现有 Store 一致）。
@MainActor
final class ResultSetStore: ObservableObject {
    static let shared = ResultSetStore()

    @Published private(set) var resultSets: [ResultSet] = []

    private let key = "SciToolbox.ResultSets"

    init() {
        load()
    }

    // MARK: - CRUD

    func create(name: String, note: String? = nil, tags: [String] = [], items: [ResultSetItem] = []) -> ResultSet {
        let set = ResultSet(name: name, note: note, tags: tags, items: SetOps.dedup(items))
        resultSets.insert(set, at: 0)
        save()
        return set
    }

    func add(items: [ResultSetItem], to id: String) {
        guard let idx = resultSets.firstIndex(where: { $0.id == id }) else { return }
        resultSets[idx].items = SetOps.dedup(resultSets[idx].items + items)
        resultSets[idx].updatedAt = Date()
        save()
    }

    func removeSet(id: String) {
        resultSets.removeAll { $0.id == id }
        save()
    }

    func rename(id: String, name: String) {
        guard let idx = resultSets.firstIndex(where: { $0.id == id }) else { return }
        resultSets[idx].name = name
        resultSets[idx].updatedAt = Date()
        save()
    }

    func updateNote(id: String, note: String?) {
        guard let idx = resultSets.firstIndex(where: { $0.id == id }) else { return }
        resultSets[idx].note = note
        resultSets[idx].updatedAt = Date()
        save()
    }

    func find(id: String) -> ResultSet? {
        resultSets.first { $0.id == id }
    }

    func clearAll() {
        resultSets.removeAll()
        save()
    }

    /// H1 备份恢复：用指定数据覆盖全部结果集。
    func restoreAll(_ items: [ResultSet]) {
        resultSets = items
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ResultSet].self, from: data) else { return }
        resultSets = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(resultSets) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
