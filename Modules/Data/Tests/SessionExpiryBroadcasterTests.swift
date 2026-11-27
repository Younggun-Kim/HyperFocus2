import Testing
@testable import Data

struct SessionExpiryBroadcasterTests {
    @Test func 만료를_알리면_구독자_모두가_받는다() async {
        let broadcaster = SessionExpiryBroadcaster()
        let first = broadcaster.stream()
        let second = broadcaster.stream()

        broadcaster.notify()

        var firstIterator = first.makeAsyncIterator()
        var secondIterator = second.makeAsyncIterator()
        let firstEvent: Void? = await firstIterator.next()
        let secondEvent: Void? = await secondIterator.next()
        #expect(firstEvent != nil)
        #expect(secondEvent != nil)
    }
}
