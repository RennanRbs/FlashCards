//
//  TagChip.swift
//  FlashCards
//

internal import SwiftUI

struct TagChip: View {
    let tag: String
    var onRemove: (() -> Void)? = nil
    var removable: Bool { onRemove != nil }

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("#\(tag)")
                .font(AppTypography.caption)
                .foregroundStyle(Color("PrimaryColor"))
            if removable {
                Button {
                    HapticsManager.selectionChanged()
                    onRemove?()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(Color("PrimaryColor").opacity(0.12), in: Capsule())
    }
}

#Preview {
    HStack {
        TagChip(tag: "iOS")
        TagChip(tag: "Swift", onRemove: {})
    }
    .padding()
}
