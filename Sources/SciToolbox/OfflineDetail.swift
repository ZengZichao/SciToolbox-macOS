import Foundation

// MARK: - OfflineDetail（B1 核心：DetailModel 的可编码离线快照）

/// `DetailModel` 含 `URL` / `XLink` / 闭包动作等不可直接 Codable 的字段，
/// 改由此平铺快照承担离线持久化职责。
///
/// 设计原则（ADR #2）：
/// - 不撬动 Provider 层 / DetailModel 结构；
/// - 快照只读足够——离线展示完整字段值，不再支持交互（链接/动作）；
/// - 在线时仍走实时拉取，离线时优先显示此快照。
struct OfflineDetail: Codable, Hashable {
    struct Row: Codable, Hashable {
        var key: String
        var value: String
        var copyable: Bool
    }
    struct Section: Codable, Hashable {
        var title: String?
        var rows: [Row]
    }
    struct FreeText: Codable, Hashable {
        var title: String?
        var text: String
        var copyable: Bool
    }
    struct Action: Codable, Hashable {
        var label: String
        var payload: String
        var kind: String  // "copy" / "export"
    }
    struct XLinkSnapshot: Codable, Hashable {
        var toolId: String
        var query: String
        var label: String
    }

    var headerTitle: String
    var headerSubtitle: String?
    var headerMeta: [String]?
    var sections: [Section]
    var freeTexts: [FreeText]
    var actions: [Action]
    var xlinks: [XLinkSnapshot]
    var sourceUrl: String?
    var capturedAt: Date

    /// 从 `DetailModel` 全量平铺为可编码快照。
    init(detail: DetailModel) {
        self.headerTitle = detail.headerTitle
        self.headerSubtitle = detail.headerSubtitle
        self.headerMeta = detail.headerMeta
        self.sections = detail.sections.map { sec in
            Section(title: sec.title, rows: sec.rows.map { Row(key: $0.key, value: $0.value, copyable: $0.copyable) })
        }
        self.freeTexts = detail.freeTextBlocks.map { FreeText(title: $0.title, text: $0.text, copyable: $0.copyable) }
        self.actions = detail.actions.map { Action(label: $0.label, payload: $0.payload, kind: $0.kind == .export ? "export" : "copy") }
        self.xlinks = detail.xlinks.map { XLinkSnapshot(toolId: $0.toolId, query: $0.query, label: $0.label) }
        self.sourceUrl = detail.webUrl
        self.capturedAt = Date()
    }

    /// Codable 的 memberwise init（测试 / 恢复用）。
    init(headerTitle: String, headerSubtitle: String? = nil, headerMeta: [String]? = nil,
         sections: [Section] = [], freeTexts: [FreeText] = [], actions: [Action] = [],
         xlinks: [XLinkSnapshot] = [], sourceUrl: String? = nil, capturedAt: Date = Date()) {
        self.headerTitle = headerTitle
        self.headerSubtitle = headerSubtitle
        self.headerMeta = headerMeta
        self.sections = sections
        self.freeTexts = freeTexts
        self.actions = actions
        self.xlinks = xlinks
        self.sourceUrl = sourceUrl
        self.capturedAt = capturedAt
    }

    /// 将快照还原为 `DetailModel` 以复用现有 `KeyValueDetail` 渲染。
    /// 丢失的字段（imageUrl / link / xlinkTarget）安全降级为 nil。
    func toDetailModel() -> DetailModel {
        DetailModel(
            headerTitle: headerTitle,
            headerSubtitle: headerSubtitle,
            headerMeta: headerMeta,
            sections: sections.map { sec in
                KVSection(title: sec.title, rows: sec.rows.map { KVRow($0.key, $0.value, copyable: $0.copyable) })
            },
            freeTextBlocks: freeTexts.map { FreeTextBlock(title: $0.title, text: $0.text, copyable: $0.copyable) },
            actions: actions.map { a in
                DetailAction(label: a.label, payload: a.payload, style: .secondary,
                             kind: a.kind == "export" ? .export : .copy)
            },
            xlinks: xlinks.map { XLink(toolId: $0.toolId, query: $0.query, label: $0.label) },
            webUrl: sourceUrl
        )
    }
}
