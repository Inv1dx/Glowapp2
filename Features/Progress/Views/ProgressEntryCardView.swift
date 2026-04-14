import SwiftUI

struct ProgressEntryCardView: View {
    let entry: ProgressEntry
    let photoStorageService: any PhotoStorageService
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ProgressCardContainer {
            VStack(alignment: .leading, spacing: GlowSpacing.medium) {
                header
                metricsRow
                photosRow
                actionsRow
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: GlowSpacing.xSmall) {
            Text(entry.checkInDate.formatted(.dateTime.month(.wide).day().year()))
                .font(GlowTypography.sectionTitle)
                .foregroundStyle(GlowColors.textPrimary)

            Text(historySubtitle)
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
        }
    }

    private var metricsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GlowSpacing.small) {
                if let weightKg = entry.weightKg {
                    ProgressMetricChip(
                        title: "Weight",
                        valueText: "\(formattedNumber(weightKg)) kg"
                    )
                }

                if let waistCm = entry.waistCm {
                    ProgressMetricChip(
                        title: "Waist",
                        valueText: "\(formattedNumber(waistCm)) cm"
                    )
                }

                if !entry.hasMetrics {
                    ProgressMetricChip(
                        title: "Check-in",
                        valueText: "Photos only"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var photosRow: some View {
        if entry.hasPhotos {
            HStack(alignment: .top, spacing: GlowSpacing.medium) {
                if let frontPhotoPath = entry.frontPhotoPath {
                    ProgressPhotoThumbnailView(
                        title: "Front",
                        source: .stored(frontPhotoPath),
                        photoStorageService: photoStorageService
                    )
                }

                if let sidePhotoPath = entry.sidePhotoPath {
                    ProgressPhotoThumbnailView(
                        title: "Side",
                        source: .stored(sidePhotoPath),
                        photoStorageService: photoStorageService
                    )
                }
            }
        } else {
            Text("No photos attached")
                .font(GlowTypography.caption)
                .foregroundStyle(GlowColors.textSecondary)
        }
    }

    private var actionsRow: some View {
        HStack {
            Button("Edit", action: onEdit)
                .font(GlowTypography.body.weight(.semibold))

            Spacer()

            Button("Delete", role: .destructive, action: onDelete)
                .font(GlowTypography.body.weight(.semibold))
        }
        .foregroundStyle(GlowColors.accent)
    }

    private var historySubtitle: String {
        if entry.hasMetrics && entry.hasPhotos {
            return "Metrics and photos"
        }

        if entry.hasPhotos {
            return "Photo check-in"
        }

        return "Metrics check-in"
    }

    private func formattedNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
