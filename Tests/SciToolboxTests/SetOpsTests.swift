import XCTest
@testable import SciToolbox

final class SetOpsTests: XCTestCase {

    private func makeItem(_ id: String, _ toolId: String = "uniprot") -> ResultSetItem {
        ResultSetItem(toolId: toolId, toolName: "Test", itemId: id, title: "Item \(id)")
    }

    // MARK: - Dedup Key

    func testDedupKeyCaseInsensitive() {
        let item1 = makeItem("P12345")
        let item2 = makeItem("p12345")
        // Different case but same dedup key
        XCTAssertEqual(SetOps.dedupKey(item1), SetOps.dedupKey(item2))
    }

    func testDedupKeyDifferentTools() {
        let item1 = makeItem("P12345", "uniprot")
        let item2 = makeItem("P12345", "pdb")
        // Same itemId but different tools → different keys
        XCTAssertNotEqual(SetOps.dedupKey(item1), SetOps.dedupKey(item2))
    }

    // MARK: - Dedup

    func testDedupRemovesDuplicates() {
        let items = [makeItem("A"), makeItem("B"), makeItem("A"), makeItem("C")]
        let deduped = SetOps.dedup(items)
        XCTAssertEqual(deduped.count, 3)
    }

    func testDedupKeepsFirst() {
        let items = [makeItem("A"), makeItem("A")]
        let deduped = SetOps.dedup(items)
        XCTAssertEqual(deduped.count, 1)
    }

    // MARK: - Union

    func testUnionNoOverlap() {
        let a = [makeItem("A"), makeItem("B")]
        let b = [makeItem("C"), makeItem("D")]
        let result = SetOps.union(a, b)
        XCTAssertEqual(result.count, 4)
    }

    func testUnionWithOverlap() {
        let a = [makeItem("A"), makeItem("B")]
        let b = [makeItem("B"), makeItem("C")]
        let result = SetOps.union(a, b)
        XCTAssertEqual(result.count, 3)
    }

    // MARK: - Intersect

    func testIntersectAllCommon() {
        let a = [makeItem("A"), makeItem("B")]
        let b = [makeItem("A"), makeItem("B")]
        let result = SetOps.intersect(a, b)
        XCTAssertEqual(result.count, 2)
    }

    func testIntersectNoneCommon() {
        let a = [makeItem("A"), makeItem("B")]
        let b = [makeItem("C"), makeItem("D")]
        let result = SetOps.intersect(a, b)
        XCTAssertEqual(result.count, 0)
    }

    func testIntersectPartial() {
        let a = [makeItem("A"), makeItem("B"), makeItem("C")]
        let b = [makeItem("B"), makeItem("C"), makeItem("D")]
        let result = SetOps.intersect(a, b)
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - Subtract

    func testSubtractAll() {
        let a = [makeItem("A"), makeItem("B")]
        let b = [makeItem("A"), makeItem("B")]
        let result = SetOps.subtract(a, b)
        XCTAssertEqual(result.count, 0)
    }

    func testSubtractNone() {
        let a = [makeItem("A"), makeItem("B")]
        let b = [makeItem("C"), makeItem("D")]
        let result = SetOps.subtract(a, b)
        XCTAssertEqual(result.count, 2)
    }

    func testSubtractPartial() {
        let a = [makeItem("A"), makeItem("B"), makeItem("C")]
        let b = [makeItem("B")]
        let result = SetOps.subtract(a, b)
        XCTAssertEqual(result.count, 2)
    }
}
