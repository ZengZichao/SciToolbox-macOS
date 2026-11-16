import Foundation

// MARK: - File Parsers（G1：4 种格式解析器）

/// 文件解析结果——统一映射为 OfflineDetail 以复用 KeyValueDetail 渲染。
struct ParsedFile {
    let detail: OfflineDetail
    let entryCount: Int
}

// MARK: - FastaParser

enum FastaParser {
    static func parse(_ content: String, filename: String) -> ParsedFile {
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        var entries: [(header: String, seq: String)] = []
        var currentHeader = ""
        var currentSeq = ""

        for line in lines {
            if line.hasPrefix(">") {
                if !currentHeader.isEmpty {
                    entries.append((currentHeader, currentSeq))
                }
                currentHeader = String(line.dropFirst())
                currentSeq = ""
            } else {
                currentSeq += line.trimmingCharacters(in: .whitespaces)
            }
        }
        if !currentHeader.isEmpty {
            entries.append((currentHeader, currentSeq))
        }

        let totalLen = entries.reduce(0) { $0 + $1.seq.count }
        let longest = entries.max(by: { $0.seq.count < $1.seq.count })

        var sections: [OfflineDetail.Section] = [
            OfflineDetail.Section(title: "Summary", rows: [
                OfflineDetail.Row(key: "Format", value: "FASTA", copyable: false),
                OfflineDetail.Row(key: "Entries", value: "\(entries.count)", copyable: false),
                OfflineDetail.Row(key: "Total length", value: "\(totalLen) bp", copyable: true),
                OfflineDetail.Row(key: "File", value: filename, copyable: false),
            ]),
        ]

        if let longest {
            sections.append(OfflineDetail.Section(title: "Longest entry", rows: [
                OfflineDetail.Row(key: "Header", value: longest.header, copyable: true),
                OfflineDetail.Row(key: "Length", value: "\(longest.seq.count) bp", copyable: true),
            ]))
        }

        sections.append(OfflineDetail.Section(title: "Entries (first 10)", rows: entries.prefix(10).map {
            OfflineDetail.Row(key: ">", value: $0.header, copyable: true)
        }))

        let detail = OfflineDetail(
            headerTitle: filename,
            headerSubtitle: "FASTA · \(entries.count) entries · \(totalLen) bp",
            headerMeta: ["Imported", "FASTA"],
            sections: sections,
            sourceUrl: nil,
            capturedAt: Date()
        )
        return ParsedFile(detail: detail, entryCount: entries.count)
    }
}

// MARK: - FastqParser

enum FastqParser {
    static func parse(_ content: String, filename: String) -> ParsedFile {
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        var reads: [(id: String, seq: String, qual: String)] = []
        var i = 0
        while i + 3 < lines.count {
            let idLine = lines[i]
            let seq = lines[i + 1]
            // lines[i+2] is "+"
            let qual = lines[i + 3]
            if idLine.hasPrefix("@") {
                reads.append((String(idLine.dropFirst()), seq, qual))
            }
            i += 4
        }

        let totalBases = reads.reduce(0) { $0 + $1.seq.count }
        let avgLen = reads.isEmpty ? 0 : totalBases / reads.count

        let sections: [OfflineDetail.Section] = [
            OfflineDetail.Section(title: "Summary", rows: [
                OfflineDetail.Row(key: "Format", value: "FASTQ", copyable: false),
                OfflineDetail.Row(key: "Reads", value: "\(reads.count)", copyable: false),
                OfflineDetail.Row(key: "Total bases", value: "\(totalBases) bp", copyable: true),
                OfflineDetail.Row(key: "Avg read length", value: "\(avgLen) bp", copyable: false),
                OfflineDetail.Row(key: "File", value: filename, copyable: false),
            ]),
            OfflineDetail.Section(title: "Reads (first 10)", rows: reads.prefix(10).map {
                OfflineDetail.Row(key: "@", value: $0.id, copyable: true)
            }),
        ]

        let detail = OfflineDetail(
            headerTitle: filename,
            headerSubtitle: "FASTQ · \(reads.count) reads · \(totalBases) bp",
            headerMeta: ["Imported", "FASTQ"],
            sections: sections,
            sourceUrl: nil,
            capturedAt: Date()
        )
        return ParsedFile(detail: detail, entryCount: reads.count)
    }
}

// MARK: - GenBankParser

enum GenBankParser {
    static func parse(_ content: String, filename: String) -> ParsedFile {
        let lines = content.components(separatedBy: "\n")

        var locus = ""
        var definition = ""
        var organism = ""
        var accession = ""
        var seqLength = ""
        var features: [(key: String, value: String)] = []
        var sequence = ""

        var inOrigin = false
        var inFeatures = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("LOCUS") {
                // LOCUS 行格式: LOCUS  <name>  <length> bp  <type>  ...  <date>
                let parts = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                if parts.count >= 2 {
                    locus = parts[1]
                }
                // 从 LOCUS 行提取声明的序列长度（如 "500 bp"）
                if let bpIndex = parts.firstIndex(where: { $0 == "bp" || $0 == "aa" }), bpIndex > 1 {
                    seqLength = "\(parts[bpIndex - 1]) \(parts[bpIndex])"
                }
            } else if trimmed.hasPrefix("DEFINITION") {
                definition = String(trimmed.dropFirst(10)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("ACCESSION") {
                accession = String(trimmed.dropFirst(9)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("ORGANISM") {
                organism = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("FEATURES") {
                inFeatures = true
                inOrigin = false
            } else if trimmed.hasPrefix("ORIGIN") {
                inFeatures = false
                inOrigin = true
            } else if inOrigin {
                // 序列行：数字 + 空格 + 碱基
                let cleaned = trimmed.replacingOccurrences(of: "[0-9 ]", with: "", options: .regularExpression)
                sequence += cleaned
            } else if inFeatures, trimmed.hasPrefix("/") {
                let kv = trimmed
                features.append(("Attribute", String(kv.dropFirst())))
            }
        }

        // 若 LOCUS 行未声明长度，从实际序列计算
        if seqLength.isEmpty && !sequence.isEmpty {
            seqLength = "\(sequence.count) bp"
        }

        var sections: [OfflineDetail.Section] = [
            OfflineDetail.Section(title: "Locus", rows: [
                OfflineDetail.Row(key: "Locus", value: locus, copyable: true),
                OfflineDetail.Row(key: "Definition", value: definition, copyable: false),
                OfflineDetail.Row(key: "Accession", value: accession, copyable: true),
                OfflineDetail.Row(key: "Organism", value: organism, copyable: false),
                OfflineDetail.Row(key: "Sequence length", value: seqLength, copyable: true),
                OfflineDetail.Row(key: "File", value: filename, copyable: false),
            ]),
        ]

        if !sequence.isEmpty {
            let preview = String(sequence.prefix(500))
            sections.append(OfflineDetail.Section(title: "Sequence (first 500 bp)", rows: [
                OfflineDetail.Row(key: "Preview", value: preview, copyable: true),
            ]))
        }

        if !features.isEmpty {
            sections.append(OfflineDetail.Section(title: "Features (\(features.count))", rows: features.prefix(20).map {
                OfflineDetail.Row(key: $0.key, value: $0.value, copyable: true)
            }))
        }

        let detail = OfflineDetail(
            headerTitle: locus.isEmpty ? filename : locus,
            headerSubtitle: "GenBank · \(accession.isEmpty ? "—" : accession) · \(seqLength.isEmpty ? "—" : seqLength)",
            headerMeta: ["Imported", "GenBank"],
            sections: sections,
            sourceUrl: nil,
            capturedAt: Date()
        )
        return ParsedFile(detail: detail, entryCount: 1)
    }
}

// MARK: - GffParser

enum GffParser {
    static func parse(_ content: String, filename: String) -> ParsedFile {
        let lines = content.components(separatedBy: "\n").filter { !$0.isEmpty && !$0.hasPrefix("#") }

        var typeCounts: [String: Int] = [:]
        var seqIds: Set<String> = []
        var examples: [(seqid: String, type: String, start: String, end: String)] = []

        for line in lines {
            let cols = line.components(separatedBy: "\t")
            guard cols.count >= 8 else { continue }
            let seqid = cols[0]
            let type = cols[2]
            let start = cols[3]
            let end = cols[4]

            seqIds.insert(seqid)
            typeCounts[type, default: 0] += 1

            if examples.count < 20 {
                examples.append((seqid, type, start, end))
            }
        }

        let sections: [OfflineDetail.Section] = [
            OfflineDetail.Section(title: "Summary", rows: [
                OfflineDetail.Row(key: "Format", value: "GFF3", copyable: false),
                OfflineDetail.Row(key: "Total features", value: "\(lines.count)", copyable: false),
                OfflineDetail.Row(key: "Sequences", value: "\(seqIds.count)", copyable: false),
                OfflineDetail.Row(key: "Feature types", value: "\(typeCounts.count)", copyable: false),
                OfflineDetail.Row(key: "File", value: filename, copyable: false),
            ]),
            OfflineDetail.Section(title: "Feature type counts", rows: typeCounts.sorted { $0.value > $1.value }.map {
                OfflineDetail.Row(key: $0.key, value: "\($0.value)", copyable: false)
            }),
            OfflineDetail.Section(title: "Examples (first 20)", rows: examples.map {
                OfflineDetail.Row(key: $0.type, value: "\($0.seqid):\($0.start)-\($0.end)", copyable: true)
            }),
        ]

        let detail = OfflineDetail(
            headerTitle: filename,
            headerSubtitle: "GFF3 · \(lines.count) features · \(seqIds.count) sequences",
            headerMeta: ["Imported", "GFF3"],
            sections: sections,
            sourceUrl: nil,
            capturedAt: Date()
        )
        return ParsedFile(detail: detail, entryCount: lines.count)
    }
}
