import Foundation

// MARK: - ToolProvider Protocol

/// A data source provider. Each public database implements one provider.
/// Semantically equivalent to the mini-program's `createSearchPage(cfg)` factory.
protocol ToolProvider: AnyObject {
    /// Unique identifier (e.g. "uniprot")
    var id: String { get }
    /// Display name (e.g. "UniProt 蛋白质")
    var name: String { get }
    /// Category for home grouping
    var category: ToolCategory { get }
    /// SF Symbol name for the tool icon
    var iconName: String { get }
    /// Search bar placeholder text
    var placeholder: String { get }
    /// Data source attribution note
    var dataSourceNote: String { get }

    /// Optional picker options (e.g. KEGG database list, Ensembl species list)
    var pickerOptions: [PickerOption]? { get }
    /// Default picker option ID (read-only; per-window state managed by SearchScreen)
    var defaultPickerId: String? { get }

    /// Basic search (offset=0, no pagination).
    func search(query: String) async throws -> SearchResult

    /// Paginated search with picker selection. Providers that support pagination
    /// or picker-based search should override this to use `pickerId` directly
    /// (avoiding shared-instance state issues in multi-window scenarios).
    func search(query: String, offset: Int, pickerId: String?) async throws -> SearchResult

    /// Fetch detail for a specific item. `context` carries extra fields from the list item.
    func detail(id: String, context: [String: String]?) async throws -> DetailModel
}

// Default implementations
extension ToolProvider {
    var pickerOptions: [PickerOption]? { nil }
    var defaultPickerId: String? { nil }

    /// 3.2：默认实现——15 个 Provider 零改动。
    /// `isLocal` 标记是否为本地离线工具（网络型 Provider 默认 false）。
    var isLocal: Bool { false }
    /// 3.2：示例查询（首批给 PubMed/UniProt/PDB/NCBI Gene 各一条，I3 引导用）。
    var sampleQueries: [String] { [] }

    /// Default: delegate to basic search, ignore pagination and picker.
    func search(query: String, offset: Int, pickerId: String?) async throws -> SearchResult {
        if offset > 0 { return SearchResult(items: [], total: 0) }
        return try await search(query: query)
    }
}

// MARK: - ToolRegistry

/// Registry of all tool providers, grouped by category.
/// Equivalent to the mini-program's `constants/tools.js` + `groupedTools()`.
final class ToolRegistry: ObservableObject, @unchecked Sendable {
    static let shared = ToolRegistry()

    @Published private(set) var providers: [any ToolProvider] = []
    /// 3.2：本地工具数组（离线可计算，无网络）。
    @Published private(set) var localTools: [LocalTool] = []

    init() {
        registerAll()
    }

    private func registerAll() {
        // 注册所有数据源
        providers = [
            UniProtProvider(),
            PDBProvider(),
            AlphaFoldProvider(),
            PubMedProvider(),
            NCBITaxonomyProvider(),
            NCBIGeneProvider(),
            EnsemblProvider(),
            KEGGProvider(),
            GOProvider(),
            PfamProvider(),
            BacDiveProvider(),
            MGnifyProvider(),
            GBIFProvider(),
            EuropePMCProvider(),
            GTDBOfficialProvider()
        ]
        // 3.2：注册本地工具（M1 阶段填充具体工具，此处先注册骨架）
        localTools = LocalToolFactory.createAll()
    }

    /// Grouped providers by category (in defined order), only non-empty groups.
    func grouped() -> [(category: ToolCategory, items: [any ToolProvider])] {
        ToolCategory.allCases.compactMap { cat in
            let items = providers.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    func find(id: String) -> (any ToolProvider)? {
        providers.first { $0.id == id }
    }

    /// 3.2：按 id 查找本地工具。
    func findLocalTool(id: String) -> LocalTool? {
        localTools.first { $0.id == id }
    }
}
