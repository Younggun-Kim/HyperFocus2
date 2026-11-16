import XCTest

final class HyperFocusUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_앱을_실행하면_인사말이_보인다() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Hello, World!"].waitForExistence(timeout: 5))
    }
}
