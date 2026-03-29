import XCTest
@testable import SipMVP

final class SalaryNormalisationServiceTests: XCTestCase {
    func testNormaliseRemovesCommasAndWhitespace() async {
        let value = await SalaryNormalisationService.normalise(" 12,340 ")
        XCTAssertEqual(value, "12340")
    }
}
