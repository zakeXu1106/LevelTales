import XCTest
@testable import LevelTales

final class LaunchRouteTests: XCTestCase {
    func testAvailableModelOpensWelcome() {
        let route = LaunchRoute.resolve(arguments: []) { true }
        XCTAssertEqual(route, .welcome)
    }

    func testUnavailableModelOpensUnsupportedPage() {
        let route = LaunchRoute.resolve(arguments: []) { false }
        XCTAssertEqual(route, .unsupported)
    }

    func testAvailableOverrideOnlyWorksInDebug() {
        let route = LaunchRoute.resolve(arguments: ["--model-available"]) { false }
        #if DEBUG
        XCTAssertEqual(route, .welcome)
        #else
        XCTAssertEqual(route, .unsupported)
        #endif
    }

    func testUnavailableOverrideOnlyWorksInDebug() {
        let route = LaunchRoute.resolve(arguments: ["--model-unavailable"]) { true }
        #if DEBUG
        XCTAssertEqual(route, .unsupported)
        #else
        XCTAssertEqual(route, .welcome)
        #endif
    }

    func testConflictingOverridesUseSystemAvailability() {
        let arguments = ["--model-available", "--model-unavailable"]
        XCTAssertEqual(LaunchRoute.resolve(arguments: arguments) { true }, .welcome)
        XCTAssertEqual(LaunchRoute.resolve(arguments: arguments) { false }, .unsupported)
    }
}
