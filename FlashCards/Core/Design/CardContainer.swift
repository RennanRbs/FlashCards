//
//  CardContainer.swift
//  FlashCards
//

internal import SwiftUI

struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("CardBackgroundColor"), in: RoundedRectangle(cornerRadius: AppSpacing.lg))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    CardContainer {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deck title")
                .font(AppTypography.title2)
            Text("32 cards • 78% dominado")
                .font(AppTypography.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
