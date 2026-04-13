import SwiftUI

@main
struct GlowAppApp: App {
    private let environment: AppEnvironment
    @StateObject private var router: AppRouter

    @MainActor
    init() {
        let environment = AppEnvironment.live
        self.environment = environment
        _router = StateObject(wrappedValue: environment.makeAppRouter())
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(router: router)
                .environment(\.appEnvironment, environment)
        }
    }
}
