import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    init(viewModel: HomeViewModel = HomeViewModel()) {
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
