import SwiftUI

enum UsageQuotaRowStyle {
    case detail
    case compact
}

struct CodexUsageLogoView: View {
    let pointSize: CGFloat

    var body: some View {
        Group {
            if let image = CodexUsageBrand.menuBarImage(
                pointSize: NSSize(width: pointSize, height: pointSize)
            ) {
                Image(nsImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: pointSize, height: pointSize)
        .accessibilityHidden(true)
    }
}

struct UsageProgressBar: View {
    let ratio: Double
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.10))

                Capsule()
                    .fill(color)
                    .frame(width: UsageProgressLayout.fillWidth(
                        totalWidth: geometry.size.width,
                        ratio: ratio
                    ))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct UsageQuotaRow: View {
    let presentation: UsageQuotaPresentation
    let window: UsageWindow
    let style: UsageQuotaRowStyle

    private var progressColor: Color {
        UsageColorPolicy.color(
            for: presentation.kind,
            remainingRatio: window.remainingRatio
        )
    }

    var body: some View {
        Group {
            switch style {
            case .detail:
                detailRow
            case .compact:
                compactRow
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilityText)
    }

    private var detailRow: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(presentation.fullResetText)
                    .font(.system(size: 13, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 138, alignment: .leading)

            UsageProgressBar(
                ratio: presentation.remainingRatio,
                color: progressColor,
                height: 7
            )
            .frame(width: 104)

            Text(presentation.remainingText)
                .font(.system(size: 14, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .trailing)
        }
        .frame(height: 58)
    }

    private var compactRow: some View {
        HStack(spacing: 6) {
            Text(presentation.compactLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18, alignment: .leading)

            Text("\(presentation.remainingPercent)%")
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .frame(
                    width: UsageQuotaRowLayout.compactPercentWidth,
                    alignment: .leading
                )

            UsageProgressBar(
                ratio: presentation.remainingRatio,
                color: progressColor,
                height: 6
            )

            Text(presentation.compactResetText)
                .font(.system(size: 12, weight: .regular))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
        .frame(height: 34)
    }
}
