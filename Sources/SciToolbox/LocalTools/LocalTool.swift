import Foundation
import SwiftUI

// MARK: - LocalTool（统一本地工具描述）

/// 本地离线计算工具的统一描述模型。
/// 与 `ToolProvider` 平行——不实现网络协议，由 `ToolRegistry.localTools` 管理。
///
/// 设计要点（3.4④）：
/// - `run` 闭包接收用户输入文本，返回 `LocalToolOutput`；
/// - 计算密集型工具在 `run` 内部自行 `Task.detached` 后回主线程；
/// - `isLocal` 始终为 true，用于侧边栏/首页「离线可用」徽标渲染。
struct LocalTool: Identifiable {
    let id: String
    let iconName: String
    let color: Color
    let titleKey: L10n
    let inputHintKey: L10n
    let run: @MainActor (String) async -> LocalToolOutput

    var name: String { L10n.t(titleKey) }
    var placeholder: String { L10n.t(inputHintKey) }
    var isLocal: Bool { true }
}

// MARK: - LocalToolOutput

/// 本地工具的统一输出模型。
struct LocalToolOutput {
    /// 顶部 KV 摘要行（可复制）。
    var summaryRows: [(String, String)]
    /// 结果正文（对齐文本 / 序列等）。
    var richText: String?
    /// 可选：复用详情渲染（如引用卡片 / 文件解析结果）。
    var detailModel: DetailModel?

    init(summaryRows: [(String, String)], richText: String? = nil, detailModel: DetailModel? = nil) {
        self.summaryRows = summaryRows
        self.richText = richText
        self.detailModel = detailModel
    }
}

// MARK: - LocalToolFactory

/// 本地工具注册工厂。
/// M1 阶段在此创建全部本地工具实例；ToolRegistry.registerAll() 调用此方法。
enum LocalToolFactory {
    static func createAll() -> [LocalTool] {
        [
            // A1：序列工具
            LocalTool(
                id: "seq-reverse-complement",
                iconName: "arrow.triangle.2.circlepath",
                color: Theme.categoryColor(.localTools),
                titleKey: .reverseComplement,
                inputHintKey: .localToolInputPlaceholder,
                run: { input in
                    let seq = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    let result = SequenceTools.reverseComplement(seq)
                    return LocalToolOutput(
                        summaryRows: [("Length", "\(result.count)"), ("Type", "DNA")],
                        richText: result
                    )
                }
            ),
            LocalTool(
                id: "seq-gc-content",
                iconName: "percent",
                color: Theme.categoryColor(.localTools),
                titleKey: .gcContent,
                inputHintKey: .localToolInputPlaceholder,
                run: { input in
                    let seq = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    let gc = SequenceTools.gcContent(seq)
                    let comp = SequenceTools.composition(seq)
                    let summary: [(String, String)] = [
                        ("GC%", String(format: "%.2f%%", gc * 100)),
                        ("Length", "\(seq.count)"),
                    ] + comp.map { (String($0.0), "\($0.1) (\(String(format: "%.1f%%", $0.2 * 100)))") }
                    return LocalToolOutput(summaryRows: summary)
                }
            ),
            LocalTool(
                id: "seq-translate",
                iconName: "textformat.abc",
                color: Theme.categoryColor(.localTools),
                titleKey: .translate,
                inputHintKey: .localToolInputPlaceholder,
                run: { input in
                    let seq = input.trimmingCharacters(in: .whitespacesAndNewlines)
                    let protein = SequenceTools.translate(dna: seq, table: .standard, readingFrame: 0)
                    return LocalToolOutput(
                        summaryRows: [("Length", "\(protein.count) aa"), ("Frame", "0 (+1)")],
                        richText: protein
                    )
                }
            ),
            // E1：全局比对
            LocalTool(
                id: "align-global",
                iconName: "arrow.left.and.right",
                color: Theme.categoryColor(.localTools),
                titleKey: .alignGlobal,
                inputHintKey: .localToolInputPlaceholder,
                run: { input in
                    let parts = input.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    guard parts.count >= 2 else {
                        return LocalToolOutput(summaryRows: [("Error", "Need 2 sequences (one per line)")])
                    }
                    let result = PairwiseAlignment.global(parts[0], parts[1])
                    return LocalToolOutput(
                        summaryRows: [
                            ("Identity", String(format: "%.1f%%", result.identity * 100)),
                            ("Score", "\(result.score)"),
                        ],
                        richText: "\(result.top)\n\(result.bottom)"
                    )
                }
            ),
            // E1：局部比对
            LocalTool(
                id: "align-local",
                iconName: "scope",
                color: Theme.categoryColor(.localTools),
                titleKey: .alignLocal,
                inputHintKey: .localToolInputPlaceholder,
                run: { input in
                    let parts = input.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    guard parts.count >= 2 else {
                        return LocalToolOutput(summaryRows: [("Error", "Need 2 sequences (one per line)")])
                    }
                    let result = PairwiseAlignment.local(parts[0], parts[1])
                    return LocalToolOutput(
                        summaryRows: [
                            ("Identity", String(format: "%.1f%%", result.identity * 100)),
                            ("Score", "\(result.score)"),
                        ],
                        richText: "\(result.top)\n\(result.bottom)"
                    )
                }
            ),
            // E2：蛋白理化性质
            LocalTool(
                id: "protein-props",
                iconName: "waveform.path.ecg",
                color: Theme.categoryColor(.localTools),
                titleKey: .lengthStats,
                inputHintKey: .localToolInputPlaceholder,
                run: { input in
                    let seq = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    let mw = ProteinProps.molecularWeight(seq: seq)
                    let pi = ProteinProps.theoreticalPI(seq: seq)
                    let ext = ProteinProps.extinctionCoefficient(seq: seq)
                    return LocalToolOutput(summaryRows: [
                        (L10n.t(.molWeight), String(format: "%.2f Da", mw)),
                        (L10n.t(.theoreticalPi), String(format: "%.2f", pi)),
                        (L10n.t(.extinctionCoeff), String(format: "%.0f / %.0f", ext.reduced, ext.oxidized)),
                        ("Length", "\(seq.count) aa"),
                    ])
                }
            ),
            // A3：批量识别
            LocalTool(
                id: "batch-identify",
                iconName: "text.badge.checkmark",
                color: Theme.categoryColor(.localTools),
                titleKey: .batchIdentify,
                inputHintKey: .localToolInputPlaceholder,
                run: { input in
                    let lines = input.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    var counts: [String: Int] = [:]
                    for line in lines {
                        let matches = AccessionRouter.classify(line)
                        if let first = matches.first {
                            counts[first.reason, default: 0] += 1
                        } else {
                            counts["Unknown", default: 0] += 1
                        }
                    }
                    let summary: [(String, String)] = [
                        ("Total", "\(lines.count)"),
                    ] + counts.sorted { $0.value > $1.value }.map { ($0.key, "\($0.value)") }
                    return LocalToolOutput(summaryRows: summary)
                }
            ),
        ]
    }
}
