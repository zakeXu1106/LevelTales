import Foundation
import FoundationModels
import SwiftUI

@main
struct LevelTalesApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var launchRoute = LevelTalesApp.resolveLaunchRoute()

    var body: some Scene {
        WindowGroup {
            Group {
                switch launchRoute {
                case .welcome:
                    WelcomeView()
                case .unsupported:
                    UnsupportedDeviceView()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    launchRoute = Self.resolveLaunchRoute()
                }
            }
        }
    }

    private static func resolveLaunchRoute() -> LaunchRoute {
        LaunchRoute.resolve(arguments: ProcessInfo.processInfo.arguments) {
            // TODO(real-device): Verify availability at startup and after returning from Settings.
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
            return false
        }
    }
}
