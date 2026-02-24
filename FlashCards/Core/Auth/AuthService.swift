//
//  AuthService.swift
//  FlashCards
//

import Foundation
import AuthenticationServices
internal import Combine

@MainActor
final class AuthService: NSObject, ObservableObject {
    /// Identificador usado quando o usuário escolhe continuar sem Apple ID (bypass). O fluxo normal com Sign in with Apple permanece intacto.
    private static let bypassUserIdentifier = "__bypass__"

    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var currentUserID: String?

    override init() {
        super.init()
        currentUserID = KeychainHelper.userIdentifier
        isLoggedIn = currentUserID != nil
        #if DEBUG
        if !isLoggedIn {
            signInBypass()
        }
        #endif
    }

    func checkSession() {
        currentUserID = KeychainHelper.userIdentifier
        isLoggedIn = currentUserID != nil
    }

    func setUserIdentifier(_ userIdentifier: String) {
        objectWillChange.send()
        KeychainHelper.userIdentifier = userIdentifier
        currentUserID = userIdentifier
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: "loggedIn")
    }

    /// Entra no app sem usar Sign in with Apple. Persiste como sessão normal; o código de login com Apple continua disponível e funcional.
    func signInBypass() {
        setUserIdentifier(Self.bypassUserIdentifier)
    }

    func signOut() {
        KeychainHelper.userIdentifier = nil
        currentUserID = nil
        isLoggedIn = false
        UserDefaults.standard.set(false, forKey: "loggedIn")
    }
}

extension AuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        let userIdentifier = credential.user
        Task { @MainActor in
            setUserIdentifier(userIdentifier)
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        // User cancelled or error – no need to change state
    }
}

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
}
