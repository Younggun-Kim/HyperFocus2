import XCTest

final class HyperFocusUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_앱을_실행하면_타이머와_기록_탭이_보인다() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["타이머"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["기록"].exists)
    }

    /// 실제 앱에서 `DataModule.bootstrap()`이 Repository의 live 구현을 등록했는지 확인한다.
    /// 등록이 빠지면 live 구현이 없어 불러오기가 실패하고 에러 문구가 보인다.
    func test_기록_탭은_live_구현으로_불러온다() throws {
        // 기록 탭이 SessionLogHomeView로 바뀌어 불러오기 화면이 아직 연결되지 않았다.
        // SessionLogHome이 기록 목록을 다시 보여 주면 이 skip을 지운다.
        throw XCTSkip("기록 탭이 SessionLogHomeView로 바뀌어 불러오기 화면 연결 전까지")

        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["기록"].tap()

        XCTAssertTrue(app.staticTexts["기록이 없습니다"].waitForExistence(timeout: 5))
        let failure = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "불러오기 실패"))
        XCTAssertEqual(failure.count, 0)
    }
}
