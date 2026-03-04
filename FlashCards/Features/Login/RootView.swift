//
//  RootView.swift
//  FlashCards
//

internal import SwiftUI

struct RootView: View {
    @StateObject private var authService = AuthService()
    @ObservedObject private var languageManager = AppLanguageManager.shared

    var body: some View {
        Group {
            if authService.isLoggedIn {
                ContentView()
            } else {
                LoginView(authService: authService)
            }
        }
        .id(languageManager.currentLanguage)
        .onAppear {
            authService.checkSession()
        }
    }
}
