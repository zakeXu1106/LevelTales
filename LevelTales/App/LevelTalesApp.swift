import Foundation
import FoundationModels
import SwiftUI

@main
struct LevelTalesApp: App {
    private let launchRoute = LaunchRoute.resolve(arguments: ProcessInfo.processInfo.arguments) {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    var body: some Scene {
        WindowGroup {
            switch launchRoute {
            case .welcome:
                WelcomeView()
            case .unsupported:
                UnsupportedDeviceView()
            }
        }
    }
}
