//
//  LoginView.swift
//  FlashCards
//

internal import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            VStack(spacing: AppSpacing.xxl) {
                Spacer()
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color("PrimaryColor"))
                    Text(L10n.appName)
                        .font(AppTypography.largeTitle)
                        .multilineTextAlignment(.center)
                    Text(L10n.appTagline)
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: AppSpacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                DispatchQueue.main.async {
                                    authService.setUserIdentifier(credential.user)
                                }
                            }
                        case .failure:
                            break
                        }
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.sm))

                    Button(L10n.continueWithoutLogin) {
                        DispatchQueue.main.async {
                            authService.signInBypass()
                        }
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)

                    Text(L10n.dataStaysOnDevice)
                        .font(AppTypography.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
    }
}

#Preview {
    LoginView(authService: AuthService())
}
