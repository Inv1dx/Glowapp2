import SwiftUI

struct NutritionLogEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let context: NutritionViewModel.EditorContext
    let onSave: (Int, Int) async -> Bool

    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var validationMessage: String?
    @State private var isSaving = false

    init(
        context: NutritionViewModel.EditorContext,
        onSave: @escaping (Int, Int) async -> Bool
    ) {
        self.context = context
        self.onSave = onSave
        _caloriesText = State(initialValue: context.initialCalories == 0 ? "" : "\(context.initialCalories)")
        _proteinText = State(initialValue: context.initialProteinGrams == 0 ? "" : "\(context.initialProteinGrams)")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Calories", text: $caloriesText)
                        .keyboardType(.numberPad)

                    TextField("Protein (g)", text: $proteinText)
                        .keyboardType(.numberPad)
                }

                Section {
                    Text(helperText)
                        .font(GlowTypography.caption)
                        .foregroundStyle(GlowColors.textSecondary)
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(GlowTypography.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(context.title)
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
                    .disabled(isSaving)
                }
            }
        }
    }

    private var helperText: String {
        "Leave one field blank if you only want to log calories or protein."
    }

    private func save() {
        let calories = Int(caloriesText) ?? 0
        let protein = Int(proteinText) ?? 0

        guard calories > 0 || protein > 0 else {
            validationMessage = "Enter calories, protein, or both."
            return
        }

        guard calories >= 0, protein >= 0 else {
            validationMessage = "Use whole numbers above zero."
            return
        }

        validationMessage = nil
        isSaving = true

        Task {
            let didSave = await onSave(calories, protein)
            isSaving = false

            if didSave {
                dismiss()
            }
        }
    }
}
