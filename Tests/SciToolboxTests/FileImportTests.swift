import XCTest
@testable import SciToolbox

final class FileImportTests: XCTestCase {

    private func loadFixture(_ name: String) -> String {
        // SPM nests test resources in *_Tests.bundle; Bundle.module points to it.
        let url = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures")
            ?? Bundle(for: FileImportTests.self).url(forResource: name, withExtension: nil, subdirectory: "Fixtures")
            ?? Bundle(for: FileImportTests.self).url(forResource: name, withExtension: nil)
            ?? Bundle.allBundles.compactMap { $0.url(forResource: name, withExtension: nil, subdirectory: "Fixtures") }
                .first
            ?? Bundle.allBundles.compactMap { $0.url(forResource: name, withExtension: nil) }
                .first
        XCTAssertNotNil(url, "Fixture \(name) not found")
        return try! String(contentsOf: url!, encoding: .utf8)
    }

    // MARK: - FASTA

    func testFastaParserBasic() {
        let content = loadFixture("sample.fasta")
        let result = FastaParser.parse(content, filename: "sample.fasta")
        XCTAssertEqual(result.entryCount, 3)
        XCTAssertEqual(result.detail.headerTitle, "sample.fasta")
        XCTAssertEqual(result.detail.sections.count, 3) // Summary + Longest + Entries
    }

    func testFastaParserEntries() {
        let content = ">seq1 test\nACGT\n>seq2 test\nCGAT"
        let result = FastaParser.parse(content, filename: "test.fa")
        XCTAssertEqual(result.entryCount, 2)
    }

    // MARK: - FASTQ

    func testFastqParserBasic() {
        let content = loadFixture("sample.fastq")
        let result = FastqParser.parse(content, filename: "sample.fastq")
        XCTAssertEqual(result.entryCount, 3)
        XCTAssertEqual(result.detail.headerTitle, "sample.fastq")
    }

    func testFastqParserReads() {
        let content = "@read1\nACGT\n+\nIIII\n@read2\nTTGC\n+\nHHHH"
        let result = FastqParser.parse(content, filename: "test.fq")
        XCTAssertEqual(result.entryCount, 2)
    }

    // MARK: - GenBank

    func testGenBankParserBasic() {
        let content = loadFixture("sample.gb")
        let result = GenBankParser.parse(content, filename: "sample.gb")
        XCTAssertEqual(result.entryCount, 1)
        XCTAssertEqual(result.detail.headerTitle, "TESTSEQ")
        XCTAssertEqual(result.detail.headerSubtitle, "GenBank · TEST001 · 500 bp")
    }

    func testGenBankParserLocus() {
        let content = "LOCUS       TESTSEQ      500 bp    DNA\n//"
        let result = GenBankParser.parse(content, filename: "test.gb")
        XCTAssertEqual(result.entryCount, 1)
        XCTAssertEqual(result.detail.headerTitle, "TESTSEQ")
    }

    // MARK: - GFF3

    func testGffParserBasic() {
        let content = loadFixture("sample.gff3")
        let result = GffParser.parse(content, filename: "sample.gff3")
        XCTAssertEqual(result.entryCount, 8)
        XCTAssertEqual(result.detail.headerTitle, "sample.gff3")
    }

    func testGffParserTypeCounts() {
        let content = "chr1\ttest\tgene\t1\t100\t.\t+\t.\tID=gene1\nchr1\ttest\texon\t1\t100\t.\t+\t.\tID=exon1\n"
        let result = GffParser.parse(content, filename: "test.gff3")
        XCTAssertEqual(result.entryCount, 2)
        // Should have 2 feature types: gene and exon
        XCTAssertTrue(result.detail.sections.contains { $0.title?.contains("Feature type") ?? false })
    }
}
