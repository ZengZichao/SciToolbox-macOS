import SwiftUI
import UniformTypeIdentifiers

// MARK: - MyFilesView（G1：我的文件——导入文件与会话内查看）

/// "我的文件"页面——展示已导入的本地文件列表，支持拖拽/选择导入。
/// G2 文件双击打开时也路由到此页面。
/// （M6 阶段会完善解析器与详情渲染，此处先提供骨架 UI。）
struct MyFilesView: View {
    @EnvironmentObject var registry: ToolRegistry
    @StateObject private var importedStore = ImportedDataStore.shared
    @State private var showFilePicker = false
    @State private var detailToShow: OfflineDetail?

    var body: some View {
        VStack(spacing: 0) {
            // 标题区
            HStack(spacing: Theme.sp3) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: Theme.fsLargeTitle, weight: .light))
                    .foregroundColor(Theme.categoryColor(.localTools))
                VStack(alignment: .leading, spacing: Theme.sp1) {
                    Text(L10n.t(.myFiles))
                        .font(.system(size: Theme.fsLargeTitle, weight: .bold))
                        .foregroundColor(Theme.ink)
                    Text(L10n.t(.offlineBadge))
                        .font(.system(size: Theme.fsCaption))
                        .foregroundColor(Theme.ink3)
                }
                Spacer()
                Button(action: { showFilePicker = true }) {
                    HStack(spacing: Theme.sp1) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 12))
                        Text(L10n.t(.importFiles))
                            .font(.system(size: Theme.fsSmall, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Theme.sp4)
                    .padding(.vertical, Theme.sp2)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm))
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityLabel(L10n.t(.importFiles))
            }
            .padding(.horizontal, Theme.sp5)
            .padding(.top, Theme.sp5)
            .padding(.bottom, Theme.sp3)

            softDivider()

            // 文件列表
            if importedStore.files.isEmpty {
                VStack(spacing: Theme.sp3) {
                    Image(systemName: "tray")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(Theme.ink4)
                    Text(L10n.t(.myFiles))
                        .font(.system(size: Theme.fsBody))
                        .foregroundColor(Theme.ink3)
                    Text(DT.t("导入 FASTA / FASTQ / GenBank / GFF3 文件离线分析", "Import FASTA / FASTQ / GenBank / GFF3 files for offline analysis"))
                        .font(.system(size: Theme.fsCaption))
                        .foregroundColor(Theme.ink3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(importedStore.files) { file in
                            fileRow(file)
                            softDivider()
                        }
                    }
                    .padding(.horizontal, Theme.sp5)
                    .padding(.top, Theme.sp3)
                }
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [
            UTType(filenameExtension: "fasta") ?? .plainText,
            UTType(filenameExtension: "fastq") ?? .plainText,
            UTType(filenameExtension: "gb") ?? .plainText,
            UTType(filenameExtension: "gff3") ?? .plainText,
            .plainText,
        ], allowsMultipleSelection: true) { result in
            switch result {
            case .success(let urls):
                for url in urls { importedStore.importFile(url: url) }
            case .failure: break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openMyFiles)) { note in
            if let url = note.userInfo?["url"] as? URL {
                importedStore.importFile(url: url)
            }
        }
        .sheet(item: Binding(
            get: { detailToShow.map { FileDetailWrapper(detail: $0) } },
            set: { detailToShow = $0?.detail }
        )) { wrapper in
            KeyValueDetail(
                model: wrapper.detail.toDetailModel(),
                accentColor: Theme.categoryColor(.localTools),
                onCopy: { Clipboard.copy($0, tip: L10n.t(.copied)) },
                onAction: { _ in },
                onXLink: { _ in }
            )
            .frame(minWidth: 500, minHeight: 400)
        }
    }

    private func fileRow(_ file: ImportedFile) -> some View {
        Button(action: { detailToShow = file.detail }) {
            HStack(spacing: Theme.sp3) {
                Image(systemName: iconName(for: file.format))
                    .font(.system(size: 16))
                    .foregroundColor(Theme.categoryColor(.localTools))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 1) {
                    Text(file.name)
                        .font(.system(size: Theme.fsBody))
                        .foregroundColor(Theme.ink)
                        .lineLimit(1)
                    Text("\(file.format.uppercased()) · \(file.entryCount) \(DT.t("条", "entries"))")
                        .font(.system(size: Theme.fsCaption))
                        .foregroundColor(Theme.ink3)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(Theme.ink4)
            }
            .padding(.horizontal, Theme.sp3)
            .padding(.vertical, Theme.sp3)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(file.name)
    }

    private func iconName(for format: String) -> String {
        switch format.lowercased() {
        case "fasta", "fa": return "doc.text"
        case "fastq", "fq": return "doc.richtext"
        case "genbank", "gb": return "doc.text.below.ecg"
        case "gff3", "gff": return "tablecells"
        default: return "doc"
        }
    }
}

private struct FileDetailWrapper: Identifiable {
    let detail: OfflineDetail
    var id: String { detail.headerTitle }
}

// MARK: - ImportedDataStore（会话内导入数据管理）

/// 管理已导入的本地文件——会话内 + UserDefaults 精简单例持久化。
/// 大内容只存文件名与统计，不落全量文本（大文件转 OfflineDetail 快照存储）。
@MainActor
final class ImportedDataStore: ObservableObject {
    static let shared = ImportedDataStore()

    @Published private(set) var files: [ImportedFile] = []

    private let key = "SciToolbox.ImportedFiles"

    init() {
        load()
    }

    func importFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        let ext = url.pathExtension.lowercased()
        let format: String
        switch ext {
        case "fasta", "fa", "faa", "fna", "ffn": format = "fasta"
        case "fastq", "fq": format = "fastq"
        case "gb", "genbank": format = "genbank"
        case "gff3", "gff": format = "gff3"
        default: format = "text"
        }

        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return }

        // 解析并生成 OfflineDetail 快照
        let detail = parseFile(content: content, format: format, filename: url.lastPathComponent)
        let entryCount = countEntries(content: content, format: format)

        let file = ImportedFile(
            id: UUID().uuidString,
            name: url.lastPathComponent,
            format: format,
            entryCount: entryCount,
            detail: detail
        )
        files.insert(file, at: 0)
        save()
    }

    func remove(id: String) {
        files.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        files.removeAll()
        save()
    }

    // MARK: - Parsing（M6：使用完整解析器）

    private func parseFile(content: String, format: String, filename: String) -> OfflineDetail {
        let parsed: ParsedFile
        switch format {
        case "fasta", "fa":
            parsed = FastaParser.parse(content, filename: filename)
        case "fastq", "fq":
            parsed = FastqParser.parse(content, filename: filename)
        case "genbank", "gb":
            parsed = GenBankParser.parse(content, filename: filename)
        case "gff3", "gff":
            parsed = GffParser.parse(content, filename: filename)
        default:
            parsed = FastaParser.parse(content, filename: filename)
        }
        return parsed.detail
    }

    private func countEntries(content: String, format: String) -> Int {
        switch format {
        case "fasta", "fa": return content.components(separatedBy: "\n").filter { $0.hasPrefix(">") }.count
        case "fastq", "fq": return max(0, content.components(separatedBy: "\n").filter { !$0.isEmpty }.count / 4)
        case "genbank", "gb": return content.contains("LOCUS") ? 1 : 0
        case "gff3", "gff": return content.components(separatedBy: "\n").filter { !$0.hasPrefix("#") && !$0.isEmpty }.count
        default: return content.components(separatedBy: "\n").count
        }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ImportedFile].self, from: data) else { return }
        files = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(files) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ImportedFile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let format: String
    let entryCount: Int
    let detail: OfflineDetail
}
