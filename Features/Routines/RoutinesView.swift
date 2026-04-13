import SwiftUI

struct RoutinesView: View {
    let viewModel: RoutinesViewModel

    init(viewModel: RoutinesViewModel = RoutinesViewModel()) {
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
