import Foundation
import Testing
@testable import CoreNetwork

struct NetworkLogTests {
    @Test func 본문이_없거나_비었으면_찍지_않는다() {
        #expect(NetworkLog.bodyDescription(nil) == nil)
        #expect(NetworkLog.bodyDescription(Data()) == nil)
    }

    @Test func 짧은_본문은_그대로_찍는다() {
        let body = Data(#"{"ok":true}"#.utf8)
        #expect(NetworkLog.bodyDescription(body) == #"{"ok":true}"#)
    }

    @Test func 긴_본문은_제한에서_자르고_전체_크기를_붙인다() {
        let body = Data(String(repeating: "a", count: 10).utf8)
        #expect(NetworkLog.bodyDescription(body, limit: 4) == "aaaa… (총 10 bytes)")
    }

    @Test func UTF8이_아니면_크기만_찍는다() {
        let body = Data([0xFF, 0xFE, 0xFD])
        #expect(NetworkLog.bodyDescription(body) == "<3 bytes, UTF-8 아님>")
    }
}
