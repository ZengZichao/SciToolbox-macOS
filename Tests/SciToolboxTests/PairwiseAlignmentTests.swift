import XCTest
@testable import SciToolbox

final class PairwiseAlignmentTests: XCTestCase {

    func testGlobalIdenticalSequences() {
        let result = PairwiseAlignment.global("ACGT", "ACGT")
        XCTAssertEqual(result.identity, 1.0, accuracy: 0.001)
        XCTAssertEqual(result.top, "ACGT")
        XCTAssertEqual(result.bottom, "ACGT")
    }

    func testGlobalWithGap() {
        let result = PairwiseAlignment.global("ACGT", "ACT")
        // Should align with a gap
        XCTAssertGreaterThan(result.identity, 0.5)
        XCTAssertEqual(result.top.count, result.bottom.count)
    }

    func testGlobalScorePositive() {
        let result = PairwiseAlignment.global("AAAA", "AAAA", match: 2, mismatch: -1, gap: -2)
        XCTAssertEqual(result.score, 8) // 4 matches × 2
    }

    func testGlobalEmpty() {
        let result = PairwiseAlignment.global("", "")
        XCTAssertEqual(result.identity, 0)
    }

    func testLocalIdenticalRegion() {
        let result = PairwiseAlignment.local("AACGTBBB", "CCCGTDDD")
        // Should find "CGT" as best local alignment
        XCTAssertGreaterThan(result.identity, 0.5)
        XCTAssertGreaterThan(result.score, 0)
    }

    func testLocalNoMatch() {
        let result = PairwiseAlignment.local("AAAA", "TTTT")
        // No positive scoring alignment
        XCTAssertEqual(result.score, 0)
    }

    func testGlobalDifferentLengths() {
        let result = PairwiseAlignment.global("ACGTACGT", "ACG")
        XCTAssertEqual(result.top.count, result.bottom.count)
        XCTAssertGreaterThan(result.top.count, 3)
    }

    func testGlobalMatchMismatch() {
        let result = PairwiseAlignment.global("ACGT", "AGGT", match: 2, mismatch: -1, gap: -2)
        // 3 matches (A, G, T) + 1 mismatch (C→G)
        XCTAssertEqual(result.identity, 0.75, accuracy: 0.01)
    }
}
