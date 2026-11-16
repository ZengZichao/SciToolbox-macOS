import Foundation

// MARK: - SequenceTools（A1：序列计算工具集）

/// 本地离线序列计算工具集——纯函数，无网络，无副作用。
struct SequenceTools {

    // MARK: - Reverse Complement

    /// DNA 反向互补链。大小写保留，非 ATGCN 字符透传（不报错）。
    static func reverseComplement(_ dna: String) -> String {
        let complement: [Character: Character] = [
            "A": "T", "a": "t",
            "T": "A", "t": "a",
            "G": "C", "g": "c",
            "C": "G", "c": "g",
            "N": "N", "n": "n",
            "U": "A", "u": "a",
            "R": "Y", "r": "y", "Y": "R", "y": "r",
            "S": "S", "s": "s", "W": "W", "w": "w",
            "K": "M", "k": "m", "M": "K", "m": "k",
            "B": "V", "b": "v", "V": "B", "v": "b",
            "D": "H", "d": "h", "H": "D", "h": "d",
        ]
        return String(dna.reversed().map { complement[$0] ?? $0 })
    }

    // MARK: - GC Content

    /// GC 含量比例（0.0–1.0）。非 ACGT 字符不计入分母。
    static func gcContent(_ seq: String) -> Double {
        let cleaned = seq.uppercased().filter { "ACGT".contains($0) }
        guard !cleaned.isEmpty else { return 0 }
        let gc = cleaned.filter { $0 == "G" || $0 == "C" }.count
        return Double(gc) / Double(cleaned.count)
    }

    // MARK: - Composition

    /// 碱基组成统计：[(字符, 计数, 比例)]，按出现频率降序。
    static func composition(_ seq: String) -> [(Character, Int, Double)] {
        let upper = seq.uppercased()
        var counts: [Character: Int] = [:]
        for ch in upper {
            counts[ch, default: 0] += 1
        }
        let total = upper.count
        return counts.sorted { $0.value > $1.value }.map { (ch, cnt) in
            (ch, cnt, total > 0 ? Double(cnt) / Double(total) : 0)
        }
    }

    // MARK: - Translation

    /// 密码子表选择。
    enum TranslationTable {
        case standard       // NCBI Table 1
        case vertebrateMitochondrial  // NCBI Table 2
        case bacterial      // NCBI Table 11 / Bacterial & Plant Plastid

        /// 密码子 → 氨基酸映射（单字母码）。
        var codonTable: [String: Character] {
            switch self {
            case .standard: return SequenceTools.standardTable
            case .vertebrateMitochondrial: return SequenceTools.vertebrateMitoTable
            case .bacterial: return SequenceTools.bacterialTable
            }
        }
    }

    /// DNA → 蛋白质翻译。
    /// - Parameters:
    ///   - dna: DNA 序列（大写或小写均可）
    ///   - table: 密码子表
    ///   - readingFrame: 0/1/2（从第 readingFrame+1 个碱基开始）
    /// - Returns: 氨基酸序列（终止密码子为 `*`）
    static func translate(dna: String, table: TranslationTable = .standard, readingFrame: Int = 0) -> String {
        let seq = dna.uppercased().filter { "ACGTN".contains($0) }
        guard seq.count > readingFrame + 2 else { return "" }
        let codons = table.codonTable
        var result = ""
        var i = seq.index(seq.startIndex, offsetBy: readingFrame)
        while i < seq.endIndex, seq.distance(from: i, to: seq.endIndex) >= 3 {
            let codon = String(seq[i..<seq.index(i, offsetBy: 3)])
            if let aa = codons[codon] {
                result.append(aa)
            } else if codon.contains("N") {
                result.append("X")
            } else {
                result.append("X")
            }
            i = seq.index(i, offsetBy: 3)
        }
        return result
    }

    // MARK: - Codon Tables

    private static let standardTable: [String: Character] = [
        // Phe
        "TTT": "F", "TTC": "F",
        // Leu
        "TTA": "L", "TTG": "L", "CTT": "L", "CTC": "L", "CTA": "L", "CTG": "L",
        // Ile
        "ATT": "I", "ATC": "I", "ATA": "I",
        // Met (Start)
        "ATG": "M",
        // Val
        "GTT": "V", "GTC": "V", "GTA": "V", "GTG": "V",
        // Ser
        "TCT": "S", "TCC": "S", "TCA": "S", "TCG": "S", "AGT": "S", "AGC": "S",
        // Pro
        "CCT": "P", "CCC": "P", "CCA": "P", "CCG": "P",
        // Thr
        "ACT": "T", "ACC": "T", "ACA": "T", "ACG": "T",
        // Ala
        "GCT": "A", "GCC": "A", "GCA": "A", "GCG": "A",
        // Tyr
        "TAT": "Y", "TAC": "Y",
        // Stop
        "TAA": "*", "TAG": "*", "TGA": "*",
        // His
        "CAT": "H", "CAC": "H",
        // Gln
        "CAA": "Q", "CAG": "Q",
        // Asn
        "AAT": "N", "AAC": "N",
        // Lys
        "AAA": "K", "AAG": "K",
        // Asp
        "GAT": "D", "GAC": "D",
        // Glu
        "GAA": "E", "GAG": "E",
        // Cys
        "TGT": "C", "TGC": "C",
        // Trp
        "TGG": "W",
        // Arg
        "CGT": "R", "CGC": "R", "CGA": "R", "CGG": "R", "AGA": "R", "AGG": "R",
        // Gly
        "GGT": "G", "GGC": "G", "GGA": "G", "GGG": "G",
    ]

    private static let vertebrateMitoTable: [String: Character] = {
        var t = standardTable
        // Vertebrate mitochondrial differences (NCBI Table 2)
        t["AGA"] = "*"  // Arg → Stop in vertebrate mito
        t["AGG"] = "*"
        t["ATA"] = "M"  // Ile → Met
        t["TGA"] = "W"  // Stop → Trp
        t["ACA"] = "T"  // (same, but explicit)
        return t
    }()

    private static let bacterialTable: [String: Character] = {
        var t = standardTable
        // Bacterial / Archaeal / Plant Plastid (NCBI Table 11)
        // Alternative start codons → M
        t["GTG"] = "M"  // Val → Met (alternative start)
        t["TTG"] = "M"  // Leu → Met (alternative start)
        t["ATT"] = "M"  // Ile → Met (alternative start)
        t["ATA"] = "M"  // Ile → Met (alternative start, rare)
        t["CTG"] = "M"  // Leu → Met (alternative start, rare)
        return t
    }()
}
