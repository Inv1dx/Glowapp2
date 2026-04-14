import PhotosUI
import SwiftUI

struct ProgressEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ProgressEntryEditorViewModel
    @State private var frontPickerItem: PhotosPickerItem?
    @State private var sidePickerItem: PhotosPickerItem?

    init(viewModel: ProgressEntryEditorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                checkInSection
                photoSection(for: .front)
                photoSection(for: .side)
                helperSection

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(GlowTypography.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .onChange(of: frontPickerItem) { item in
                Task {
                    await viewModel.importPhoto(from: item, role: .front)
                    frontPickerItem = nil
                }
            }
            .onChange(of: sidePickerItem) { item in
                Task {
                    await viewModel.importPhoto(from: item, role: .side)
                    sidePickerItem = nil
                }
            }
        }
    }

    private var checkInSection: some View {
        Section("Check-in") {
            DatePicker(
                "Date",
                selection: $viewModel.checkInDate,
                in: ...Date(),
                displayedComponents: .date
            )

            TextField("Weight (kg)", text: $viewModel.weightText)
                .keyboardType(.decimalPad)

            TextField("Waist (cm)", text: $viewModel.waistText)
                .keyboardType(.decimalPad)
        }
    }

    private func photoSection(for role: ProgressPhotoRole) -> some View {
        Section(role.title) {
            ProgressPhotoThumbnailView(
                title: role == .front ? "Front" : "Side",
                source: photoSource(for: role),
                photoStorageService: viewModel.photoStorageService,
                emptyText: role == .front ? "Optional photo" : "Optional side angle"
            )

            PhotosPicker(
                selection: pickerBinding(for: role),
                matching: .images
            ) {
                Label(
                    pickerTitle(for: role),
                    systemImage: "photo.on.rectangle"
                )
            }

            if hasPhoto(for: role) {
                Button("Remove photo", role: .destructive) {
                    viewModel.removePhoto(role: role)
                }
            }
        }
    }

    private var helperSection: some View {
        Section {
            Text("Save weight, waist, or at least one photo. Photos stay local to this device for now.")
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("If Photos access is denied or limited, you can still save a metrics-only check-in.")
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pickerBinding(for role: ProgressPhotoRole) -> Binding<PhotosPickerItem?> {
        switch role {
        case .front:
            return $frontPickerItem
        case .side:
            return $sidePickerItem
        }
    }

    private func hasPhoto(for role: ProgressPhotoRole) -> Bool {
        switch role {
        case .front:
            viewModel.frontPhotoState.hasPhoto
        case .side:
            viewModel.sidePhotoState.hasPhoto
        }
    }

    private func pickerTitle(for role: ProgressPhotoRole) -> String {
        if hasPhoto(for: role) {
            return "Replace \(role.rawValue) photo"
        }

        return "Add \(role.rawValue) photo"
    }

    private func photoSource(for role: ProgressPhotoRole) -> ProgressPhotoThumbnailSource? {
        switch role {
        case .front:
            return photoSource(from: viewModel.frontPhotoState)
        case .side:
            return photoSource(from: viewModel.sidePhotoState)
        }
    }

    private func photoSource(
        from state: ProgressEntryEditorViewModel.PhotoState
    ) -> ProgressPhotoThumbnailSource? {
        switch state {
        case .empty:
            return nil
        case .stored(let path):
            return .stored(path)
        case .imported(let image, _):
            return .imported(image)
        }
    }

    private func save() {
        Task {
            let didSave = await viewModel.save()

            if didSave {
                dismiss()
            }
        }
    }
}
