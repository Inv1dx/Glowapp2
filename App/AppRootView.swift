import SwiftUI

struct AppRootView: View {
    @ObservedObject var router: AppRouter

    var body: some View {
        Group {
            switch router.rootDestination {
            case .mainTabs:
                AppShellView(router: router)
            }
        }
    }
}
