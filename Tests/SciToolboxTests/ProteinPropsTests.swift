import XCTest
@testable import SciToolbox

final class ProteinPropsTests: XCTestCase {

    func testMolecularWeightSingle() {
        // Single amino acid A (Ala) = 71.0788 + 18.0153 (water) = 89.0941
        let mw = ProteinProps.molecularWeight(seq: "A")
        XCTAssertEqual(mw, 89.0941, accuracy: 0.01)
    }

    func testMolecularWeightDipeptide() {
        // AA = 71.0788 * 2 + 18.0153 (water) = 160.1729
        let mw = ProteinProps.molecularWeight(seq: "AA")
        XCTAssertEqual(mw, 160.1729, accuracy: 0.01)
    }

    func testMolecularWeightInsulin() {
        // Insulin A chain (21 aa): GIVEQCCTSICSLYQLENYCN
        let mw = ProteinProps.molecularWeight(seq: "GIVEQCCTSICSLYQLENYCN")
        // Expected ~2384 Da (approximate)
        XCTAssertGreaterThan(mw, 2300)
        XCTAssertLessThan(mw, 2500)
    }

    func testTheoreticalPIBasicProtein() {
        // KKKKK is very basic → pI should be high
        let pi = ProteinProps.theoreticalPI(seq: "KKKKK")
        XCTAssertGreaterThan(pi, 10.0)
    }

    func testTheoreticalPIAcidicProtein() {
        // DDDDD is very acidic → pI should be low
        let pi = ProteinProps.theoreticalPI(seq: "DDDDD")
        XCTAssertLessThan(pi, 5.0)
    }

    func testTheoreticalPIEmpty() {
        let pi = ProteinProps.theoreticalPI(seq: "")
        XCTAssertEqual(pi, 0.0)
    }

    func testExtinctionCoefficientNoWY() {
        // No Trp or Tyr → reduced = 0
        let ext = ProteinProps.extinctionCoefficient(seq: "AAAA")
        XCTAssertEqual(ext.reduced, 0.0)
        XCTAssertEqual(ext.oxidized, 0.0)
    }

    func testExtinctionCoefficientWithTrp() {
        // 1 Trp → 5500
        let ext = ProteinProps.extinctionCoefficient(seq: "W")
        XCTAssertEqual(ext.reduced, 5500.0)
    }

    func testExtinctionCoefficientWithTyr() {
        // 1 Tyr → 1490
        let ext = ProteinProps.extinctionCoefficient(seq: "Y")
        XCTAssertEqual(ext.reduced, 1490.0)
    }

    func testExtinctionCoefficientWithCys() {
        // 2 Cys → oxidized adds 125
        let ext = ProteinProps.extinctionCoefficient(seq: "CC")
        XCTAssertEqual(ext.reduced, 0.0)
        XCTAssertEqual(ext.oxidized, 125.0) // 2/2 = 1 disulfide × 125
    }
}
