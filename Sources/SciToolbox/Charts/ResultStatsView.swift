import SwiftUI
import Charts

// MARK: - ResultStatsView（C1/C2：结果统计与图表）

/// 结果统计条——对已加载结果客户端统计：总数、来源计数、类别计数、年份分布。
/// 数据少于 2 组时仅显示文字统计不渲染图表。
struct ResultStatsView: View {
    let items: [ResultItem]
    let providerName: String?
    let accentColor: Color

    init(items: [ResultItem], providerName: String? = nil, accentColor: Color = Theme.accent) {
        self.items = items
        self.providerName = providerName
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.sp3) {
            // 统计摘要
            HStack(spacing: Theme.sp4) {
                statBadge(label: L10n.t(.resultCount, items.count), value: nil, icon: "list.bullet")
                if !sourceCounts.isEmpty {
                    statBadge(label: DT.t("来源", "Sources"), value: "\(sourceCounts.count)", icon: "globe.asia.australia")
                }
                if !yearCounts.isEmpty {
                    statBadge(label: DT.t("年份", "Years"), value: "\(yearCounts.count)", icon: "calendar")
                }
                Spacer()
            }

            // 图表：仅在有足够数据时渲染
            if items.count >= 2 && !chartData.isEmpty {
                Chart(chartData) { item in
                    BarMark(
                        x: .value("Label", item.label),
                        y: .value("Count", item.value)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(3)
                }
                .frame(height: 120)
                .padding(Theme.sp3)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
            }
        }
        .padding(.horizontal, Theme.sp5)
        .padding(.vertical, Theme.sp2)
    }

    // MARK: - Statistics

    private struct StatItem: Identifiable {
        let id = UUID()
        let label: String
        let value: Int
        let color: Color
    }

    private var sourceCounts: [(String, Int)] {
        guard let providerName else { return [] }
        return [(providerName, items.count)]
    }

    private var yearCounts: [(String, Int)] {
        var counts: [String: Int] = [:]
        for item in items {
            if let meta = item.meta {
                // 从 meta 中提取 YYYY 年份
                if let year = extractYear(from: meta) {
                    counts[year, default: 0] += 1
                }
            }
        }
        return counts.sorted { $0.key < $1.key }.map { (key: $0.key, value: $0.value) }
    }

    private var chartData: [StatItem] {
        if !yearCounts.isEmpty {
            return yearCounts.map { StatItem(label: $0.0, value: $0.1, color: accentColor) }
        }
        // 无年份时显示来源对比
        return sourceCounts.map { StatItem(label: $0.0, value: $0.1, color: accentColor) }
    }

    private func extractYear(from text: String) -> String? {
        let pattern = #"\b(19|20)\d{2}\b"#
        if let range = text.range(of: pattern, options: .regularExpression) {
            return String(text[range])
        }
        return nil
    }

    private func statBadge(label: String, value: String?, icon: String) -> some View {
        HStack(spacing: Theme.sp1 + 2) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(accentColor)
            Text(label)
                .font(.system(size: Theme.fsSmall))
                .foregroundColor(Theme.ink3)
        }
        .padding(.horizontal, Theme.sp3)
        .padding(.vertical, Theme.sp1 + 2)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm))
    }
}
