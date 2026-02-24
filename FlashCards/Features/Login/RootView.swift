//
//  RootView.swift
//  FlashCards
//

internal import SwiftUI

struct RootView: View {
    @StateObject private var authService = AuthService()

    var body: some View {
        Group {
            if authService.isLoggedIn {
                ContentView()
            } else {
                LoginView(authService: authService)
            }
        }
        .onAppear {
            authService.checkSession()
        }
    }
}
