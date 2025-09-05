import Testing
import UIKit
import OSLog
@testable import JQSPM
@testable import JQSPM_UI
@available(iOS 14.0, *)
@Test func example() async throws {
    // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    let log = await JQLog.instance(enable: true)
    await log.success("SUCCESS->>>>")
    NetworkMonitorManager().start()
}
