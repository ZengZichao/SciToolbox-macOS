import SwiftUI

// MARK: - LocalToolView（本地工具通用骨架 UI）

/// 本地工具的通用渲染骨架：输入区 → 工具栏 → 结果区。
/// 所有本地工具共用此视图，通过 `LocalTool.run` 闭包驱动结果渲染。
struct LocalToolView: View {
    let tool: LocalTool

    @State private var input: String = ""
    @State private var output: LocalToolOutput?
    @State private var isRunning = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            // 输入区
            VStack(alignment: .leading, spacing: Theme.sp2) {
                Text(tool.name)
                    .font(.system(size: Theme.fsHeadline, weight: .semibold))
                    .foregroundColor(Theme.ink)

                // 离线可用徽标
                HStack(spacing: Theme.sp1) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 10))
                    Text(L10n.t(.offlineBadge))
                        .font(.system(size: Theme.fsCaption))
                }
                .foregroundColor(Theme.categoryColor(.localTools))
                .padding(.horizontal, Theme.sp2)
                .padding(.vertical, Theme.sp1)
                .background(Theme.categoryColor(.localTools).opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm))

                TextEditor(text: $input)
                    .font(.system(size: Theme.fsBody, design: .monospaced))
                    .frame(minHeight: 80)
                    .padding(Theme.sp2)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusMd)
                            .strokeBorder(Theme.line, lineWidth: 0.5)
                    )
                    .opacity(input.isEmpty ? 0.6 : 1.0)
                    .overlay(alignment: .topLeading) {
                        if input.isEmpty {
                            Text(tool.placeholder)
                                .font(.system(size: Theme.fsBody, design: .monospaced))
                                .foregroundColor(Theme.ink4)
                                .padding(.horizontal, Theme.sp3)
                                .padding(.vertical, Theme.sp3)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .padding(.horizontal, Theme.sp5)
            .padding(.top, Theme.sp5)
            .padding(.bottom, Theme.sp3)

            // 工具栏
            HStack(spacing: Theme.sp3) {
                Spacer()
                Button(action: runTool) {
                    HStack(spacing: Theme.sp1) {
                        if isRunning {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(L10n.t(.runTool))
                            .font(.system(size: Theme.fsBody, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.sp4)
                    .padding(.vertical, Theme.sp2)
                    .background(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Theme.ink4 : Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunning)
                .accessibilityLabel(L10n.t(.runTool))
            }
            .padding(.horizontal, Theme.sp5)
            .padding(.bottom, Theme.sp3)

            softDivider()

            // 结果区
            if let output {
                resultView(output)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            } else {
                Spacer()
                VStack(spacing: Theme.sp2) {
                    Image(systemName: tool.iconName)
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(Theme.ink4)
                    Text(L10n.t(.toolResult))
                        .font(.system(size: Theme.fsSmall))
                        .foregroundColor(Theme.ink3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: output != nil)
    }

    // MARK: - Result rendering

    @ViewBuilder
    private func resultView(_ output: LocalToolOutput) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.sp4) {
                // KV 摘要行
                if !output.summaryRows.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(output.summaryRows.enumerated()), id: \.offset) { _, row in
                            HStack(alignment: .top, spacing: Theme.sp4) {
                                Text(row.0)
                                    .font(.system(size: Theme.fsSmall))
                                    .foregroundColor(Theme.ink3)
                                    .frame(minWidth: 88, maxWidth: 120, alignment: .leading)
                                Text(row.1)
                                    .font(.system(size: Theme.fsBody, design: .monospaced))
                                    .foregroundColor(Theme.ink)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Button(action: { Clipboard.copy(row.1, tip: L10n.t(.copied)) }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 10))
                                        .foregroundColor(Theme.ink3)
                                }
                                .buttonStyle(PressableButtonStyle())
                                .opacity(0.6)
                                .accessibilityLabel(L10n.t(.copyKey, row.0))
                            }
                            .padding(.vertical, Theme.sp1 + 2)
                        }
                    }
                    .padding(Theme.sp4)
                    .cardStyle()
                }

                // 富文本结果
                if let rich = output.richText, !rich.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.sp2) {
                        HStack {
                            Text(L10n.t(.toolResult))
                                .font(.system(size: Theme.fsCaption))
                                .foregroundColor(Theme.ink3)
                                .textCase(.uppercase)
                                .tracking(Theme.trackSection)
                            Spacer()
                            Button(action: { Clipboard.copy(rich, tip: L10n.t(.copied)) }) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 10))
                                    .foregroundColor(Theme.ink3)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .opacity(0.6)
                            .accessibilityLabel(L10n.t(.copyKey, L10n.t(.toolResult)))
                        }
                        Text(rich)
                            .font(.system(size: Theme.fsBody, design: .monospaced))
                            .foregroundColor(Theme.ink)
                            .textSelection(.enabled)
                            .lineSpacing(2)
                    }
                    .padding(Theme.sp4)
                    .cardStyle()
                }

                // DetailModel 渲染（如引用卡片）
                if let model = output.detailModel {
                    KeyValueDetail(
                        model: model,
                        accentColor: Theme.categoryColor(.localTools),
                        onCopy: { Clipboard.copy($0, tip: L10n.t(.copied)) },
                        onAction: { action in
                            if action.kind == .export {
                                let base = action.exportFileName ?? "citation"
                                let ext = action.exportExt ?? "txt"
                                let ok = ExportUtil.saveTextFile(action.payload, defaultName: base, ext: ext)
                                if ok { Clipboard.showToast(L10n.t(.exported, "\(base).\(ext)")) }
                            } else {
                                Clipboard.copy(action.payload, tip: action.label)
                            }
                        },
                        onXLink: { _ in }
                    )
                }
            }
            .padding(.horizontal, Theme.sp5)
            .padding(.top, Theme.sp4)
            .padding(.bottom, Theme.sp8)
        }
    }

    // MARK: - Run

    private func runTool() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isRunning = true
        Task { @MainActor in
            // 计算密集型工具放后台队列
            let result = await Task.detached(priority: .userInitiated) {
                await tool.run(trimmed)
            }.value
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                self.output = result
            }
            self.isRunning = false
        }
    }
}

// MARK: - LocalToolsListView（本地工具列表页）

/// 本地工具列表页——在侧边栏「本地工具」分组下展示全部离线工具。
struct LocalToolsListView: View {
    @EnvironmentObject var registry: ToolRegistry
    @State private var selectedToolId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 标题区
                VStack(alignment: .leading, spacing: Theme.sp2) {
                    HStack(spacing: Theme.sp2) {
                        Image(systemName: "function")
                            .font(.system(size: Theme.fsLargeTitle, weight: .light))
                            .foregroundColor(Theme.categoryColor(.localTools))
                        VStack(alignment: .leading, spacing: Theme.sp1) {
                            Text(L10n.t(.localToolsSection))
                                .font(.system(size: Theme.fsLargeTitle, weight: .bold))
                                .foregroundColor(Theme.ink)
                            HStack(spacing: Theme.sp1) {
                                Image(systemName: "wifi.slash")
                                    .font(.system(size: 10))
                                Text(L10n.t(.offlineBadge))
                                    .font(.system(size: Theme.fsCaption))
                            }
                            .foregroundColor(Theme.categoryColor(.localTools))
                        }
                    }
                    .padding(.horizontal, Theme.sp5)
                    .padding(.top, Theme.sp5)
                    .padding(.bottom, Theme.sp4)
                }

                // 工具卡片
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.sp3) {
                    ForEach(registry.localTools) { tool in
                        localToolCard(tool)
                    }
                }
                .padding(.horizontal, Theme.sp5)
                .padding(.bottom, Theme.sp8)
            }
        }
    }

    private func localToolCard(_ tool: LocalTool) -> some View {
        Button(action: { selectedToolId = tool.id }) {
            HStack(spacing: Theme.sp3) {
                Image(systemName: tool.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(tool.color)
                    .frame(width: 28, height: 28)
                    .background(tool.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm))
                VStack(alignment: .leading, spacing: 1) {
                    Text(tool.name)
                        .font(.system(size: Theme.fsBody))
                        .foregroundColor(Theme.ink)
                    Text(L10n.t(.offlineBadge))
                        .font(.system(size: Theme.fsCaption))
                        .foregroundColor(Theme.ink3)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(Theme.ink4)
            }
            .padding(.horizontal, Theme.sp3)
            .padding(.vertical, Theme.sp3)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusMd)
                    .strokeBorder(Theme.line, lineWidth: 0.5)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(tool.name)
        .sheet(isPresented: Binding(
            get: { selectedToolId == tool.id },
            set: { if !$0 { selectedToolId = nil } }
        )) {
            LocalToolView(tool: tool)
                .frame(minWidth: 600, minHeight: 500)
        }
    }
}
