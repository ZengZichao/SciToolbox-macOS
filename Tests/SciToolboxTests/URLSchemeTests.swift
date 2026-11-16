import XCTest
@testable import SciToolbox

final class URLSchemeTests: XCTestCase {

    @MainActor
    func testSearchRoute() {
        let url = URL(string: "scitoolbox://search?tool=uniprot&q=P12345")!
        let route = URLSchemeRouter.shared.parse(url)
        switch route {
        case .search(let toolId, let query):
            XCTAssertEqual(toolId, "uniprot")
            XCTAssertEqual(query, "P12345")
        default:
            XCTFail("Expected .search route")
        }
    }

    @MainActor
    func testIdentifyRoute() {
        let url = URL(string: "scitoolbox://identify?text=P12345")!
        let route = URLSchemeRouter.shared.parse(url)
        switch route {
        case .identify(let text):
            XCTAssertEqual(text, "P12345")
        default:
            XCTFail("Expected .identify route")
        }
    }

    @MainActor
    func testOpenLocalToolsRoute() {
        let url = URL(string: "scitoolbox://localtools")!
        let route = URLSchemeRouter.shared.parse(url)
        switch route {
        case .openLocalTools:
            break // Expected
        default:
            XCTFail("Expected .openLocalTools route")
        }
    }

    @MainActor
    func testOpenMyFilesRoute() {
        let url = URL(string: "scitoolbox://myfiles")!
        let route = URLSchemeRouter.shared.parse(url)
        switch route {
        case .openMyFiles:
            break // Expected
        default:
            XCTFail("Expected .openMyFiles route")
        }
    }

    @MainActor
    func testUnknownRoute() {
        let url = URL(string: "https://example.com")!
        let route = URLSchemeRouter.shared.parse(url)
        switch route {
        case .unknown:
            break // Expected
        default:
            XCTFail("Expected .unknown route")
        }
    }

    @MainActor
    func testSearchRouteMissingParams() {
        let url = URL(string: "scitoolbox://search")!
        let route = URLSchemeRouter.shared.parse(url)
        switch route {
        case .unknown:
            break // Expected - missing params
        default:
            XCTFail("Expected .unknown for missing params")
        }
    }
}
