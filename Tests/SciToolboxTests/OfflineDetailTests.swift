import XCTest
@testable import SciToolbox

final class OfflineDetailTests: XCTestCase {

    func testRoundTripConversion() {
        let original = DetailModel(
            headerTitle: "Test Protein",
            headerSubtitle: "Homo sapiens",
            headerMeta: ["ID: P12345", "Length: 100 aa"],
            sections: [
                KVSection(title: "Function", rows: [
                    KVRow("Function", "Test function description", copyable: false),
                    KVRow("Length", "100 aa", copyable: true),
                ]),
                KVSection(title: "Sequence", rows: [
                    KVRow("Mass", "11234.5 Da", copyable: true),
                ]),
            ],
            freeTextBlocks: [
                FreeTextBlock(title: "Abstract", text: "This is a test abstract.", copyable: false),
            ],
            actions: [
                DetailAction(label: "Copy BibTeX", payload: "@article{test}", style: .secondary, kind: .export),
            ],
            xlinks: [
                XLink(toolId: "pdb", query: "1ABC", label: "PDB: 1ABC"),
            ],
            webUrl: "https://example.com/P12345"
        )

        // Convert to OfflineDetail
        let offline = OfflineDetail(detail: original)

        XCTAssertEqual(offline.headerTitle, original.headerTitle)
        XCTAssertEqual(offline.headerSubtitle, original.headerSubtitle)
        XCTAssertEqual(offline.headerMeta, original.headerMeta)
        XCTAssertEqual(offline.sections.count, original.sections.count)
        XCTAssertEqual(offline.sections[0].rows.count, original.sections[0].rows.count)
        XCTAssertEqual(offline.sections[0].rows[0].key, original.sections[0].rows[0].key)
        XCTAssertEqual(offline.sections[0].rows[0].value, original.sections[0].rows[0].value)
        XCTAssertEqual(offline.freeTexts.count, original.freeTextBlocks.count)
        XCTAssertEqual(offline.freeTexts[0].text, original.freeTextBlocks[0].text)
        XCTAssertEqual(offline.actions.count, original.actions.count)
        XCTAssertEqual(offline.actions[0].label, original.actions[0].label)
        XCTAssertEqual(offline.actions[0].kind, "export")
        XCTAssertEqual(offline.xlinks.count, original.xlinks.count)
        XCTAssertEqual(offline.xlinks[0].toolId, original.xlinks[0].toolId)
        XCTAssertEqual(offline.sourceUrl, original.webUrl)

        // Convert back to DetailModel
        let restored = offline.toDetailModel()
        XCTAssertEqual(restored.headerTitle, original.headerTitle)
        XCTAssertEqual(restored.headerSubtitle, original.headerSubtitle)
        XCTAssertEqual(restored.sections.count, original.sections.count)
        XCTAssertEqual(restored.sections[0].rows.count, original.sections[0].rows.count)
        XCTAssertEqual(restored.freeTextBlocks.count, original.freeTextBlocks.count)
        XCTAssertEqual(restored.actions.count, original.actions.count)
        XCTAssertEqual(restored.xlinks.count, original.xlinks.count)
        XCTAssertEqual(restored.webUrl, original.webUrl)
    }

    func testCodableRoundTrip() throws {
        let detail = OfflineDetail(
            headerTitle: "Test",
            headerSubtitle: "subtitle",
            headerMeta: ["meta1", "meta2"],
            sections: [
                OfflineDetail.Section(title: "S1", rows: [
                    OfflineDetail.Row(key: "K1", value: "V1", copyable: true),
                ]),
            ],
            freeTexts: [],
            actions: [],
            xlinks: [],
            sourceUrl: "https://example.com",
            capturedAt: Date()
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(detail)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(OfflineDetail.self, from: data)

        XCTAssertEqual(decoded.headerTitle, detail.headerTitle)
        XCTAssertEqual(decoded.sections.count, detail.sections.count)
        XCTAssertEqual(decoded.sections[0].rows[0].key, detail.sections[0].rows[0].key)
    }
}
