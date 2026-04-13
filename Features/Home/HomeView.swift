import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @StateObject private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        DashboardView(
            viewModel: viewModel,
            onOpenSettings: openSettings
        )
        .navigationTitle(viewModel.navigationTitle)
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(url)
    }
}
