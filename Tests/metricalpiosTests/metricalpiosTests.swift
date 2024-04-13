import XCTest
@testable import metricalpios

final class metricalpiosTests: XCTestCase {
    func testExample() throws {
        Metricalp.initMetricalp(attributes: ["tid": "mam48", "app": "ExampleiOSApp@1.0.0", "metr_user_language": "English-US", "metr_unique_identifier": "<GENERATED_UUID>"], initialScreen:"MainScreen")
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
}
