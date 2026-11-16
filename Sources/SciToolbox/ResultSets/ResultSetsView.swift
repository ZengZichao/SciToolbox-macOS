import SwiftUI
import AppKit

// MARK: - ResultSetsView（F1/F2：结果集列表与集合运算）

/// 结果集列表页——在侧边栏作为独立页签。
struct ResultSetsView: View {
    @StateObject private var store = ResultSetStore.shared
    @StateObject private var favorites = LocalFavorites.shared
    @State private var showCreateSheet = false
    @State private var newName = ""
    @State private var selectedSetId: String?
    @State private var showSetOps = false
    @State private var secondSetId: String?
    @State private var setOpResult: [ResultSetItem]?
    @State private var setOpLabel: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: Theme.sp3) {
                Text(L10n.t(.saveAsResultSet))
                    .font(.system(size: Theme.fsHeadline, weight: .semibold))
                    .foregroundColor(Theme.ink)
                Text(L10n.t(.resultCount, store.resultSets.count))
                    .font(.system(size: Theme.fsSmall))
                    .foregroundColor(Theme.ink3)
                Spacer()
                Button(action: { showCreateSheet = true }) {
                    Label(L10n.t(.newCollection), systemImage: "plus")
                        .font(.system(size: Theme.fsSmall))
                        .foregroundColor(Theme.accent)
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, Theme.sp6)
            .padding(.vertical, Theme.sp4)

            thinDivider()

            if store.resultSets.isEmpty {
                StateView(state: .empty(text: DT.t(
                    "暂无结果集\n在搜索结果中点击「保存为结果集」即可创建",
                    "No result sets yet\nUse \"Save as Result Set\" from search results to create one"
                )))
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.resultSets) { set in
                            resultSetRow(set)
                            thinDivider()
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.t(.saveAsResultSet))
        .sheet(isPresented: $showCreateSheet) {
            createSheet
        }
        .sheet(isPresented: $showSetOps) {
            setOpsSheet
        }
    }

    private func resultSetRow(_ set: ResultSet) -> some View {
        VStack(alignment: .leading, spacing: Theme.sp2) {
            HStack(spacing: Theme.sp3) {
                Image(systemName: "tray.full")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.accent.opacity(0.7))

                VStack(alignment: .leading, spacing: 1) {
                    Text(set.name)
                        .font(.system(size: Theme.fsBody))
                        .foregroundColor(Theme.ink)
                    Text("\(set.items.count) \(DT.t("条", "items")) · \(set.relativeUpdated)")
                        .font(.system(size: Theme.fsCaption))
                        .foregroundColor(Theme.ink3)
                }

                Spacer()

                // 集合运算入口
                Button(action: {
                    selectedSetId = set.id
                    showSetOps = true
                }) {
                    Image(systemName: "circle.dashed")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.ink3)
                }
                .buttonStyle(PressableButtonStyle())
                .help(DT.t("集合运算", "Set Operations"))
                .accessibilityLabel(DT.t("集合运算", "Set Operations"))

                // 删除
                Button(action: { store.removeSet(id: set.id) }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.ink3)
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(L10n.t(.clearAll))
            }

            // 条目前 5 条预览
            if !set.items.isEmpty {
                ForEach(Array(set.items.prefix(5))) { item in
                    HStack(spacing: Theme.sp2) {
                        Text(item.toolName)
                            .font(.system(size: Theme.fsCaption))
                            .foregroundColor(Theme.ink3)
                            .frame(width: 80, alignment: .leading)
                        Text(item.title)
                            .font(.system(size: Theme.fsSmall))
                            .foregroundColor(Theme.ink2)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.leading, Theme.sp6)
                }
                if set.items.count > 5 {
                    Text("… +\(set.items.count - 5)")
                        .font(.system(size: Theme.fsCaption))
                        .foregroundColor(Theme.ink4)
                        .padding(.leading, Theme.sp6)
                }
            }
        }
        .padding(.horizontal, Theme.sp5)
        .padding(.vertical, Theme.sp3)
    }

    // MARK: - Create sheet

    private var createSheet: some View {
        VStack(spacing: Theme.sp4) {
            Text(L10n.t(.saveAsResultSet))
                .font(.system(size: Theme.fsHeadline, weight: .semibold))
            TextField(L10n.t(.resultSetName), text: $newName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button(L10n.t(.cancelBtn)) { showCreateSheet = false; newName = "" }
                    .buttonStyle(PressableButtonStyle())
                Button(L10n.t(.save)) {
                    if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                        _ = store.create(name: newName)
                    }
                    showCreateSheet = false
                    newName = ""
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(Theme.sp5)
        .frame(width: 360)
    }

    // MARK: - Set Ops sheet

    private var setOpsSheet: some View {
        VStack(spacing: Theme.sp4) {
            Text(DT.t("集合运算", "Set Operations"))
                .font(.system(size: Theme.fsHeadline, weight: .semibold))

            if let firstId = selectedSetId,
               let firstSet = store.find(id: firstId) {
                Text("\(firstSet.name) (\(firstSet.items.count))")
                    .font(.system(size: Theme.fsSmall))
                    .foregroundColor(Theme.ink3)

                Picker(DT.t("与", "with"), selection: $secondSetId) {
                    Text(DT.t("选择结果集", "Select set")).tag(String?.none)
                    ForEach(store.resultSets.filter { $0.id != firstId }) { s in
                        Text("\(s.name) (\(s.items.count))").tag(Optional(s.id))
                    }
                }

                if let secondId = secondSetId,
                   let secondSet = store.find(id: secondId) {
                    HStack(spacing: Theme.sp3) {
                        opButton(L10n.t(.union)) { previewOp(.union, first: firstSet.items, second: secondSet.items) }
                        opButton(L10n.t(.intersect)) { previewOp(.intersect, first: firstSet.items, second: secondSet.items) }
                        opButton(L10n.t(.diff)) { previewOp(.diff, first: firstSet.items, second: secondSet.items) }
                    }

                    if let result = setOpResult, let label = setOpLabel {
                        Text("\(label): \(result.count) \(DT.t("条", "items"))")
                            .font(.system(size: Theme.fsSmall, weight: .medium))
                            .foregroundColor(Theme.accent)

                        Button(DT.t("保存为新结果集", "Save as new set")) {
                            let name = "\(firstSet.name) \(label) \(secondSet.name)"
                            _ = store.create(name: name, items: result)
                            showSetOps = false
                            setOpResult = nil
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
            }

            Spacer()
            Button(L10n.t(.close)) { showSetOps = false; setOpResult = nil }
                .buttonStyle(PressableButtonStyle())
        }
        .padding(Theme.sp5)
        .frame(width: 420, height: 380)
    }

    private enum SetOp { case union, intersect, diff }

    private func opButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: Theme.fsSmall, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, Theme.sp4)
                .padding(.vertical, Theme.sp2)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func previewOp(_ op: SetOp, first: [ResultSetItem], second: [ResultSetItem]) {
        switch op {
        case .union:
            setOpResult = SetOps.union(first, second)
            setOpLabel = L10n.t(.union)
        case .intersect:
            setOpResult = SetOps.intersect(first, second)
            setOpLabel = L10n.t(.intersect)
        case .diff:
            setOpResult = SetOps.subtract(first, second)
            setOpLabel = L10n.t(.diff)
        }
    }
}

// MARK: - ResultSet relative time

extension ResultSet {
    var relativeUpdated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = AppLanguage.currentLocale
        formatter.unitsStyle = .short
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}
