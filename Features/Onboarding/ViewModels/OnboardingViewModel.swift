import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case welcome
        case valueProposition
        case goalSelection
        case targetSetup
        case completion

        var index: Int {
            rawValue + 1
        }
    }

    @Published private(set) var step: Step = .welcome
    @Published var displayName = "" {
        didSet { handleInputChange() }
    }
    @Published var primaryGoal: UserProfile.PrimaryGoal = UserProfile.defaultPrimaryGoal {
        didSet { handleInputChange() }
    }
    @Published var targetDailySteps: Int = UserProfile.defaultDailySteps {
        didSet { handleInputChange() }
    }
    @Published var targetSleepHours: Double = UserProfile.defaultSleepHours {
        didSet { handleInputChange() }
    }
    @Published var targetProteinGrams: Int = UserProfile.defaultProteinGrams {
        didSet { handleInputChange() }
    }
    @Published var targetWaterML: Int = UserProfile.defaultWaterML {
        didSet { handleInputChange() }
    }
    @Published private(set) var validationMessages: [UserProfile.Field: String] = [:]
    @Published private(set) var saveErrorMessage: String?
    @Published private(set) var isSaving = false

    private let userRepository: any UserRepository

    init(userRepository: any UserRepository) {
        self.userRepository = userRepository
        validateInputs()
    }

    var totalSteps: Int {
        Step.allCases.count
    }

    var completionTitle: String {
        let trimmedName = UserProfile.trimmedDisplayName(displayName)
        return trimmedName.isEmpty ? "You're ready" : "\(trimmedName), you're ready"
    }

    var selectedGoalTitle: String {
        primaryGoal.title
    }

    var summaryItems: [String] {
        [
            primaryGoal.title,
            "\(targetDailySteps.formatted()) steps a day",
            "\(targetSleepHours.formatted()) hours of sleep",
            "\(targetProteinGrams.formatted()) g protein",
            "\(targetWaterML.formatted()) ml water"
        ]
    }

    func goBack() {
        saveErrorMessage = nil

        guard let previousStep = Step(rawValue: step.rawValue - 1) else {
            return
        }

        step = previousStep
    }

    func advance() {
        saveErrorMessage = nil

        switch step {
        case .welcome:
            step = .valueProposition
        case .valueProposition:
            step = .goalSelection
        case .goalSelection:
            step = .targetSetup
        case .targetSetup:
            continueFromTargets()
        case .completion:
            break
        }
    }

    func continueFromTargets() {
        validateInputs()

        guard validationMessages.isEmpty else {
            return
        }

        step = .completion
    }

    func completeOnboarding() async -> Bool {
        validateInputs()

        guard validationMessages.isEmpty else {
            step = .targetSetup
            return false
        }

        isSaving = true
        saveErrorMessage = nil

        do {
            try await userRepository.saveUserProfile(makeUserProfile(onboardingCompleted: true))
            isSaving = false
            return true
        } catch UserRepositoryError.invalidProfile(let issues) {
            validationMessages = Self.makeValidationDictionary(from: issues)
            step = .targetSetup
            isSaving = false
            return false
        } catch {
            saveErrorMessage = "Couldn't save your setup. Try again."
            isSaving = false
            return false
        }
    }

    func validationMessage(for field: UserProfile.Field) -> String? {
        validationMessages[field]
    }

    private func handleInputChange() {
        validateInputs()
        saveErrorMessage = nil
    }

    private func validateInputs() {
        validationMessages = Self.makeValidationDictionary(
            from: makeUserProfile(onboardingCompleted: false).validationIssues
        )
    }

    private func makeUserProfile(onboardingCompleted: Bool) -> UserProfile {
        UserProfile(
            displayName: displayName,
            primaryGoal: primaryGoal,
            targetDailySteps: targetDailySteps,
            targetSleepHours: targetSleepHours,
            targetProteinGrams: targetProteinGrams,
            targetWaterML: targetWaterML,
            onboardingCompleted: onboardingCompleted
        )
    }

    private static func makeValidationDictionary(
        from issues: [UserProfile.ValidationIssue]
    ) -> [UserProfile.Field: String] {
        Dictionary(uniqueKeysWithValues: issues.map { ($0.field, $0.message) })
    }
}
