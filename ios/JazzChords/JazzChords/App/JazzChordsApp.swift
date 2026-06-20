// App entry point. Sets up the root scene + the shared environment.

import SwiftUI

@main
struct JazzChordsApp: App {
    @Environment(\.colorScheme) private var systemScheme

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.init(hex: "f5a623")) // amber accent across the app
        }
    }
}
