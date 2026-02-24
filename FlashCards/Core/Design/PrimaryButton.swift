//
//  PrimaryButton.swift
//  FlashCards
//

internal import SwiftUI

struct PrimaryButton: View {
    let title: String
    let style: Style
    let action: () -> Void

    enum Style {
        case primary
        case success
        case error
        case secondary
    }

    init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return Color("PrimaryColor")
        case .success: return Color("SuccessColor")
        case .error: return Color("ErrorColor")
        case .secondary: return Color("CardBackgroundColor")
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .success, .error: return .white
        case .secondary: return Color("PrimaryColor")
        }
    }

    var body: some View {
        Button(action: {
            HapticsManager.light()
            action()
        }) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: AppSpacing.sm))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Primary", style: .primary) {}
        PrimaryButton("Success", style: .success) {}
        PrimaryButton("Error", style: .error) {}
        PrimaryButton("Secondary", style: .secondary) {}
    }
    .padding()
}
