enum LaunchRoute: Equatable {
    case welcome
    case unsupported

    static func resolve(arguments: [String], systemIsAvailable: () -> Bool) -> Self {
        #if DEBUG
        let forceAvailable = arguments.contains("--model-available")
        let forceUnavailable = arguments.contains("--model-unavailable")

        switch (forceAvailable, forceUnavailable) {
        case (true, false): return .welcome
        case (false, true): return .unsupported
        default: break
        }
        #endif

        return systemIsAvailable() ? .welcome : .unsupported
    }
}
