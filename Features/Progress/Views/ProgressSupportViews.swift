import SwiftUI
import UIKit

struct ProgressCardContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GlowSpacing.cardPadding)
            .background(GlowColors.surface)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GlowSpacing.cornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: GlowSpacing.cornerRadius,
                    style: .continuous
                )
                .stroke(GlowColors.border, lineWidth: 1)
            )
    }
}

struct ProgressSectionHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(title)
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(subtitle)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ProgressSummaryMetricCardView: View {
    let metric: ProgressSummaryMetric

    var body: some View {
        ProgressCardContainer {
            VStack(alignment: .leading, spacing: GlowSpacing.small) {
                Text(metric.title)
                    .font(GlowTypography.caption.weight(.semibold))
                    .foregroundStyle(GlowColors.textSecondary)

                Text(metric.valueText)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(GlowColors.textPrimary)

                Text(metric.detailText)
                    .font(GlowTypography.caption)
                    .foregroundStyle(GlowColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

enum ProgressPhotoThumbnailSource {
    case stored(String)
    case imported(UIImage)
}

struct ProgressPhotoThumbnailView: View {
    let title: String
    let source: ProgressPhotoThumbnailSource?
    let photoStorageService: any PhotoStorageService
    var emptyText: String = "No photo"

    var body: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(title)
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textSecondary)

            ZStack {
                RoundedRectangle(
                    cornerRadius: GlowSpacing.medium,
                    style: .continuous
                )
                .fill(GlowColors.background)

                if let image = resolvedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: GlowSpacing.xSmall) {
                        Image(systemName: source == nil ? "photo" : "exclamationmark.triangle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(GlowColors.textSecondary)

                        Text(placeholderText)
                            .font(GlowTypography.caption)
                            .foregroundStyle(GlowColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(GlowSpacing.small)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: GlowSpacing.medium,
                    style: .continuous
                )
            )
        }
    }

    private var placeholderText: String {
        if case .stored = source {
            return "Photo unavailable"
        }

        return emptyText
    }

    private var resolvedImage: UIImage? {
        switch source {
        case .none:
            return nil
        case .imported(let image):
            return image
        case .stored(let path):
            guard let url = photoStorageService.imageURL(for: path) else {
                return nil
            }

            return UIImage(contentsOfFile: url.path)
        }
    }
}

struct ProgressMetricChip: View {
    let title: String
    let valueText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(GlowTypography.caption.weight(.semibold))
                .foregroundStyle(GlowColors.textSecondary)

            Text(valueText)
                .font(GlowTypography.body.weight(.semibold))
                .foregroundStyle(GlowColors.textPrimary)
        }
        .padding(.horizontal, GlowSpacing.medium)
        .padding(.vertical, GlowSpacing.small)
        .background(GlowColors.accentMuted)
        .clipShape(Capsule())
    }
}
