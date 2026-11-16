import XCTest
@testable import SciToolbox

final class LocalToolsTests: XCTestCase {

    // MARK: - Reverse Complement

    func testReverseComplementSimple() {
        XCTAssertEqual(SequenceTools.reverseComplement("ACGT"), "ACGT")
    }

    func testReverseComplementLowercase() {
        XCTAssertEqual(SequenceTools.reverseComplement("acgt"), "acgt")
    }

    func testReverseComplementMixed() {
        XCTAssertEqual(SequenceTools.reverseComplement("ATGC"), "GCAT")
    }

    func testReverseComplementWithN() {
        XCTAssertEqual(SequenceTools.reverseComplement("ACGTN"), "NACGT")
    }

    func testReverseComplementEmpty() {
        XCTAssertEqual(SequenceTools.reverseComplement(""), "")
    }

    func testReverseComplementNonStandard() {
        // R (A/G) complements to Y (C/T)
        XCTAssertEqual(SequenceTools.reverseComplement("R"), "Y")
        XCTAssertEqual(SequenceTools.reverseComplement("Y"), "R")
    }

    // MARK: - GC Content

    func testGCContentAllGC() {
        XCTAssertEqual(SequenceTools.gcContent("GCGC"), 1.0)
    }

    func testGCContentNone() {
        XCTAssertEqual(SequenceTools.gcContent("ATAT"), 0.0)
    }

    func testGCContentMixed() {
        XCTAssertEqual(SequenceTools.gcContent("ATGC"), 0.5, accuracy: 0.001)
    }

    func testGCContentEmpty() {
        XCTAssertEqual(SequenceTools.gcContent(""), 0.0)
    }

    func testGCContentIgnoresNonACGT() {
        // N is not counted
        XCTAssertEqual(SequenceTools.gcContent("GCNN"), 1.0)
    }

    // MARK: - Composition

    func testCompositionBasic() {
        let comp = SequenceTools.composition("AATTGGCC")
        XCTAssertEqual(comp.count, 4)
        // Each base appears twice
        for entry in comp {
            XCTAssertEqual(entry.1, 2)
            XCTAssertEqual(entry.2, 0.25, accuracy: 0.001)
        }
    }

    // MARK: - Translation

    func testTranslateStartCodon() {
        // ATG = Met (M)
        XCTAssertEqual(SequenceTools.translate(dna: "ATG"), "M")
    }

    func testTranslateStopCodon() {
        // TAA = Stop (*)
        XCTAssertEqual(SequenceTools.translate(dna: "TAA"), "*")
    }

    func testTranslateFullSequence() {
        // ATG TTT AAA TAA = M F K *
        XCTAssertEqual(SequenceTools.translate(dna: "ATGTTTAAATAA"), "MFK*")
    }

    func testTranslateReadingFrame() {
        // Frame 1 skips first base
        let seq = "CATGTTTAAATAA"
        // Frame 0: H M F K *
        // Frame 1: I V L N (starts from index 1)
        let frame0 = SequenceTools.translate(dna: seq, readingFrame: 0)
        let frame1 = SequenceTools.translate(dna: seq, readingFrame: 1)
        XCTAssertNotEqual(frame0, frame1)
    }

    func testTranslateWithN() {
        // NNN → XXX (unknown)
        let result = SequenceTools.translate(dna: "NNN")
        XCTAssertEqual(result, "X")
    }

    func testTranslateBacterialTable() {
        // GTG is Val in standard, Met in bacterial (alternative start)
        let standard = SequenceTools.translate(dna: "GTG", table: .standard)
        let bacterial = SequenceTools.translate(dna: "GTG", table: .bacterial)
        XCTAssertEqual(standard, "V")
        XCTAssertEqual(bacterial, "M")
    }

    // MARK: - Batch Accession

    func testBatchIdentifyMixed() {
        // Should not crash and return some result
        let matches = AccessionRouter.classify("P12345")
        XCTAssertFalse(matches.isEmpty)
    }
}
