import SwiftUI

struct OnboardingScaffoldView<Content: View>: View {
    let step: Int
    let totalSteps: Int
    let title: String
    let message: String
    let primaryButtonTitle: String
    let primaryAction: () -> Void
    var primaryButtonSystemImage: String? = "arrow.right"
    var isPrimaryDisabled = false
    var isPrimaryLoading = false
    var backAction: (() -> Void)? = nil
    var noticeMessage: String? = nil
    let content: Content

    init(
        step: Int,
        totalSteps: Int,
        title: String,
        message: String,
        primaryButtonTitle: String,
        primaryAction: @escaping () -> Void,
        primaryButtonSystemImage: String? = "arrow.right",
        isPrimaryDisabled: Bool = false,
        isPrimaryLoading: Bool = false,
        backAction: (() -> Void)? = nil,
        noticeMessage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.step = step
        self.totalSteps = totalSteps
        self.title = title
        self.message = message
        self.primaryButtonTitle = primaryButtonTitle
        self.primaryAction = primaryAction
        self.primaryButtonSystemImage = primaryButtonSystemImage
        self.isPrimaryDisabled = isPrimaryDisabled
        self.isPrimaryLoading = isPrimaryLoading
        self.backAction = backAction
        self.noticeMessage = noticeMessage
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GlowSpacing.large) {
                topBar
                header

                if let noticeMessage {
                    noticeBanner(message: noticeMessage)
                }

                content
            }
            .padding(GlowSpacing.screenPadding)
            .padding(.bottom, GlowSpacing.xLarge * 3)
        }
        .background(GlowColors.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var topBar: some View {
        HStack(spacing: GlowSpacing.medium) {
            if let backAction {
                Button(action: backAction) {
                    Label("Back", systemImage: "chevron.left")
                        .font(GlowTypography.caption.weight(.semibold))
                        .foregroundStyle(GlowColors.textPrimary)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(width: 60, height: 24)
            }

            progressTrack
        }
    }

    private var progressTrack: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text("Step \(step) of \(totalSteps)")
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)

            HStack(spacing: GlowSpacing.xSmall) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index < step ? GlowColors.accent : GlowColors.accentMuted)
                        .frame(height: 8)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.small) {
            Text(AppConstants.Shell.appName)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)

            Text(title)
                .font(GlowTypography.screenTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(message)
                .font(GlowTypography.body)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bottomBar: some View {
        VStack {
            PrimaryButton(
                title: primaryButtonTitle,
                systemImage: primaryButtonSystemImage,
                isEnabled: !isPrimaryDisabled,
                isLoading: isPrimaryLoading,
                action: primaryAction
            )
        }
        .padding(GlowSpacing.screenPadding)
        .background(GlowColors.surface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(GlowColors.border)
                .frame(height: 1)
        }
    }

    private func noticeBanner(message: String) -> some View {
        Text(message)
            .font(GlowTypography.caption)
            .foregroundStyle(GlowColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GlowSpacing.medium)
            .background(GlowColors.accentMuted)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GlowSpacing.cornerRadius,
                    style: .continuous
                )
            )
    }
}
