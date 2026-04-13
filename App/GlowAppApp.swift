import SwiftUI

@main
struct GlowAppApp: App {
    private let environment = AppEnvironment.live
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            AppRootView(router: router)
                .environment(\.appEnvironment, environment)
        }
    }
}
