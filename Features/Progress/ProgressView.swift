import SwiftUI

struct ProgressView: View {
    let viewModel: ProgressViewModel

    init(viewModel: ProgressViewModel = ProgressViewModel()) {
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
