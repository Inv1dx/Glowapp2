import SwiftUI

struct SettingsView: View {
    let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        FeaturePlaceholderView(
            title: viewModel.title,
            message: viewModel.message,
            highlights: viewModel.highlights,
            buttonTitle: viewModel.buttonTitle,
            buttonSystemImage: viewModel.buttonSystemImage,
            onPrimaryAction: {}
        )
        .navigationTitle(viewModel.navigationTitle)
    }
}
