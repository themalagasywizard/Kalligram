import SwiftUI

struct HistorySnapshotRow: View {
    let snapshot: ProjectSnapshot
    let isSelected: Bool
    let isHead: Bool
    let iconName: String
    let onSelect: () -> Void
    let onRestore: () -> Void
    let onBranch: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Spacing.sm) {
                // Preview thumbnail
                SnapshotThumbnail(path: snapshot.previewImagePath)

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack {
                        Image(systemName: iconName)
                            .font(.system(size: 10))
                            .foregroundStyle(ColorPalette.textTertiary)
                        Text(snapshot.label)
                            .font(Typography.bodySmall)
                            .fontWeight(isSelected ? .medium : .regular)
                            .foregroundStyle(ColorPalette.textPrimary)
                            .lineLimit(1)
                        if isHead {
                            Text("HEAD")
                                .font(Typography.caption2)
                                .foregroundStyle(ColorPalette.accentBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(ColorPalette.accentBlue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: Spacing.sm) {
                        Text(snapshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(Typography.caption2)
                            .foregroundStyle(ColorPalette.textTertiary)
                        Text("\(snapshot.wordCount) words")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorPalette.textTertiary)
                        Text("\(max(1, snapshot.pageCount)) pages")
                            .font(Typography.caption2)
                            .foregroundStyle(ColorPalette.textTertiary)
                    }
                }

                Spacer()

                // Restore button (visible on hover)
                if isHovered {
                    HStack(spacing: Spacing.xs) {
                        Button(action: onBranch) {
                            Text("Branch")
                                .font(Typography.caption2)
                                .foregroundStyle(ColorPalette.textPrimary)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 2)
                                .background(ColorPalette.surfaceTertiary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button(action: onRestore) {
                            Text("Restore")
                                .font(Typography.caption2)
                                .foregroundStyle(ColorPalette.accentBlue)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, 2)
                                .background(ColorPalette.accentBlue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.vertical, Spacing.xs)
            .padding(.horizontal, Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Spacing.radiusSmall)
                    .fill(isSelected ? ColorPalette.accentBlue.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(AnimationTokens.snappy) {
                isHovered = hovering
            }
        }
    }
}

private struct SnapshotThumbnail: View {
    let path: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(ColorPalette.surfaceTertiary)
                .frame(width: 44, height: 62)

            if let image = ProjectSnapshotPreviewService.previewImage(from: path) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 62)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundStyle(ColorPalette.textTertiary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(ColorPalette.borderSubtle, lineWidth: 1)
        )
    }
}
