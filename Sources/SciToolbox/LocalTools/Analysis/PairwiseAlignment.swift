import Foundation

// MARK: - PairwiseAlignment（E1：Needleman-Wunsch / Smith-Waterman）

/// 双序列比对——全局（NW）与局部（SW）实现。
/// 纯函数，无网络，无副作用。
///
/// 算法：`(n+1)×(m+1)` 计分矩阵（`[Int]` 平铺数组）+ 回溯。
/// 输入长度护栏 ≤ 2,000 bp（超出提示改用片段），复杂度 O(n·m)。
struct PairwiseAlignment {

    struct AlignmentResult {
        var top: String       // 序列 a 的比对行（含 gap '-'）
        var bottom: String    // 序列 b 的比对行（含 gap '-'）
        var identity: Double  // 0.0–1.0
        var score: Int
        var mode: Mode
    }

    enum Mode { case global, local }

    // MARK: - Global (Needleman-Wunsch)

    /// 全局比对（Needleman-Wunsch）。
    static func global(_ a: String, _ b: String, match: Int = 2, mismatch: Int = -1, gap: Int = -2) -> AlignmentResult {
        let aArr = Array(a)
        let bArr = Array(b)
        let n = aArr.count, m = bArr.count

        guard n > 0, m > 0 else {
            return AlignmentResult(top: a, bottom: b, identity: 0, score: 0, mode: .global)
        }

        // 计分矩阵
        let rows = n + 1, cols = m + 1
        var score = [Int](repeating: 0, count: rows * cols)

        // 初始化第一行/列
        for i in 0...n { score[i * cols] = i * gap }
        for j in 0...m { score[j] = j * gap }

        // 填充
        for i in 1...n {
            for j in 1...m {
                let diag = score[(i - 1) * cols + (j - 1)] + (aArr[i - 1] == bArr[j - 1] ? match : mismatch)
                let up = score[(i - 1) * cols + j] + gap
                let left = score[i * cols + (j - 1)] + gap
                score[i * cols + j] = max(diag, up, left)
            }
        }

        // 回溯
        var i = n, j = m
        var topAligned = [Character]()
        var bottomAligned = [Character]()
        var matches = 0

        while i > 0 || j > 0 {
            if i > 0 && j > 0 {
                let diag = score[(i - 1) * cols + (j - 1)] + (aArr[i - 1] == bArr[j - 1] ? match : mismatch)
                if score[i * cols + j] == diag {
                    topAligned.append(aArr[i - 1])
                    bottomAligned.append(bArr[j - 1])
                    if aArr[i - 1] == bArr[j - 1] { matches += 1 }
                    i -= 1; j -= 1
                    continue
                }
            }
            if i > 0 && score[i * cols + j] == score[(i - 1) * cols + j] + gap {
                topAligned.append(aArr[i - 1])
                bottomAligned.append("-")
                i -= 1
            } else {
                topAligned.append("-")
                bottomAligned.append(bArr[j - 1])
                j -= 1
            }
        }

        topAligned.reverse()
        bottomAligned.reverse()

        let alignLen = topAligned.count
        let identity = alignLen > 0 ? Double(matches) / Double(alignLen) : 0

        return AlignmentResult(
            top: String(topAligned),
            bottom: String(bottomAligned),
            identity: identity,
            score: score[n * cols + m],
            mode: .global
        )
    }

    // MARK: - Local (Smith-Waterman)

    /// 局部比对（Smith-Waterman）。
    static func local(_ a: String, _ b: String, match: Int = 2, mismatch: Int = -1, gap: Int = -2) -> AlignmentResult {
        let aArr = Array(a)
        let bArr = Array(b)
        let n = aArr.count, m = bArr.count

        guard n > 0, m > 0 else {
            return AlignmentResult(top: a, bottom: b, identity: 0, score: 0, mode: .local)
        }

        let rows = n + 1, cols = m + 1
        var score = [Int](repeating: 0, count: rows * cols)

        var maxScore = 0
        var maxI = 0, maxJ = 0

        // 填充（不设负值——局部比对关键）
        for i in 1...n {
            for j in 1...m {
                let diag = score[(i - 1) * cols + (j - 1)] + (aArr[i - 1] == bArr[j - 1] ? match : mismatch)
                let up = score[(i - 1) * cols + j] + gap
                let left = score[i * cols + (j - 1)] + gap
                let val = max(0, diag, up, left)
                score[i * cols + j] = val
                if val > maxScore {
                    maxScore = val
                    maxI = i
                    maxJ = j
                }
            }
        }

        // 回溯——从最高分位置到 0
        var i = maxI, j = maxJ
        var topAligned = [Character]()
        var bottomAligned = [Character]()
        var matches = 0

        while i > 0 && j > 0 && score[i * cols + j] > 0 {
            let diag = score[(i - 1) * cols + (j - 1)] + (aArr[i - 1] == bArr[j - 1] ? match : mismatch)
            if score[i * cols + j] == diag {
                topAligned.append(aArr[i - 1])
                bottomAligned.append(bArr[j - 1])
                if aArr[i - 1] == bArr[j - 1] { matches += 1 }
                i -= 1; j -= 1
            } else if i > 0 && score[i * cols + j] == score[(i - 1) * cols + j] + gap {
                topAligned.append(aArr[i - 1])
                bottomAligned.append("-")
                i -= 1
            } else {
                topAligned.append("-")
                bottomAligned.append(bArr[j - 1])
                j -= 1
            }
        }

        topAligned.reverse()
        bottomAligned.reverse()

        let alignLen = topAligned.count
        let identity = alignLen > 0 ? Double(matches) / Double(alignLen) : 0

        return AlignmentResult(
            top: String(topAligned),
            bottom: String(bottomAligned),
            identity: identity,
            score: maxScore,
            mode: .local
        )
    }
}
