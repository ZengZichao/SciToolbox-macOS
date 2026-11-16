import Foundation

// MARK: - ProteinProps（E2：蛋白质理化性质计算）

/// 蛋白质理化性质计算器——纯函数，无网络，无副作用。
/// 基于氨基酸平均质量与 pK 表的迭代法。
struct ProteinProps {

    // MARK: - Molecular Weight

    /// 氨基酸平均分子量（Da，不含水）。
    private static let aaMW: [Character: Double] = [
        "A": 71.0788, "R": 156.1875, "N": 114.1038, "D": 115.0886,
        "C": 103.1388, "E": 129.1155, "Q": 128.1307, "G": 57.0519,
        "H": 137.1411, "I": 113.1594, "L": 113.1594, "K": 128.1741,
        "M": 131.1926, "F": 147.1766, "P": 97.1167, "S": 87.0782,
        "T": 101.1051, "W": 186.2132, "Y": 163.1760, "V": 99.1326,
    ]

    /// 分子量（Da）= Σ(残基质量) + 18.0153（末端水分子）。
    /// aaMW 表存储的是氨基酸残基质量（已脱水），因此只需加回一个水分子。
    static func molecularWeight(seq: String) -> Double {
        let aa = seq.uppercased().filter { aaMW.keys.contains($0) }
        guard !aa.isEmpty else { return 0 }
        let total = aa.reduce(0.0) { $0 + (aaMW[$1] ?? 0) }
        return total + 18.0153
    }

    // MARK: - Theoretical pI

    /// Bjellqvist pK 表（适用于肽链内残基，游离氨基酸不同）。
    private static let pKN_terminal = 8.0    // N-terminus (average)
    private static let pKC_terminal = 3.55   // C-terminus (average)
    private static let pK: [Character: (acid: Double, basic: Double)] = [
        // (pK_COOH, pK_NH3) — 仅可电离侧链有非零值
        "C": (8.5, 0),    // Cys 侧链 -SH
        "D": (4.05, 0),   // Asp 侧链 -COOH
        "E": (4.45, 0),   // Glu 侧链 -COOH
        "H": (0, 6.0),    // His 侧链咪唑基
        "K": (0, 10.0),   // Lys 侧链 -NH3+
        "R": (0, 12.0),   // Arg 侧链胍基
        "Y": (10.0, 0),   // Tyr 侧链 -OH
    ]

    /// 理论等电点（pI）——二分法迭代解电荷净零。
    /// 采用 Bjellqvist pK 值，步长 0.01，精度 0.01。
    static func theoreticalPI(seq: String) -> Double {
        let aa = seq.uppercased()
        guard !aa.isEmpty else { return 0 }

        // 计数各可电离残基
        var counts: [Character: Int] = [:]
        for ch in aa { counts[ch, default: 0] += 1 }

        func netCharge(at pH: Double) -> Double {
            var charge = 0.0
            // N-terminus (positive)
            charge += 1.0 / (1.0 + pow(10.0, pH - pKN_terminal))
            // C-terminus (negative)
            charge -= 1.0 / (1.0 + pow(10.0, pKC_terminal - pH))
            // Side chains
            for (ch, cnt) in counts {
                guard let pk = pK[ch] else { continue }
                if pk.acid > 0 {
                    // Acidic: COOH → COO⁻ + H⁺ (negative when deprotonated)
                    charge -= Double(cnt) / (1.0 + pow(10.0, pk.acid - pH))
                }
                if pk.basic > 0 {
                    // Basic: NH3⁺ → NH2 + H⁺ (positive when protonated)
                    charge += Double(cnt) / (1.0 + pow(10.0, pH - pk.basic))
                }
            }
            return charge
        }

        // Bisection: find pH where charge ≈ 0
        var lo = 0.0, hi = 14.0
        for _ in 0..<100 {
            let mid = (lo + hi) / 2.0
            let c = netCharge(at: mid)
            if abs(c) < 0.001 { return mid }
            if c > 0 { lo = mid } else { hi = mid }
        }
        return (lo + hi) / 2.0
    }

    // MARK: - Extinction Coefficient

    /// 消光系数（ε₂₈₀）——基于 Trp / Tyr / Cys 含量。
    /// 返回 (reduced: 还原型, oxidized: 氧化型/二硫键)。
    /// 使用 Pace & Schmid (1995) 值：Trp=5500, Tyr=1490, Cys(oxidized)=125。
    static func extinctionCoefficient(seq: String, withCys: Bool = true) -> (reduced: Double, oxidized: Double) {
        let aa = seq.uppercased()
        let nW = aa.filter { $0 == "W" }.count
        let nY = aa.filter { $0 == "Y" }.count
        let nC = aa.filter { $0 == "C" }.count

        let reduced = Double(nW) * 5500.0 + Double(nY) * 1490.0
        let oxidized = reduced + Double(nC / 2) * 125.0  // Cys 形成二硫键

        return (reduced, oxidized)
    }
}
