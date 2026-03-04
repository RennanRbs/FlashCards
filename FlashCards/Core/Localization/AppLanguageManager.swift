//
//  AppLanguageManager.swift
//  FlashCards
//

import Foundation
internal import SwiftUI
internal import Combine

private enum StorageKeys {
    static let appLanguage = "app_language"
}

/// Idiomas suportados pelo app. O usuário pode escolher nas configurações ou usar o do sistema.
enum AppLanguage: String, CaseIterable, Identifiable {
    case ptBR = "pt-BR"
    case en = "en"
    case fr = "fr"
    case zhHans = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ptBR: return "Português (Brasil)"
        case .en: return "English"
        case .fr: return "Français"
        case .zhHans: return "简体中文"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

/// Gerencia o idioma do app: detecta do sistema ou usa o escolhido pelo usuário nas configurações.
final class AppLanguageManager: ObservableObject {
    
    static let shared = AppLanguageManager()

    @Published private(set) var currentLanguage: AppLanguage

    init() {
        if let stored = UserDefaults.standard.string(forKey: StorageKeys.appLanguage),
           let lang = AppLanguage(rawValue: stored) {
            currentLanguage = lang
        } else {
            currentLanguage = Self.languageFromSystem()
        }
    }

    /// Bundle a usar para strings localizadas (idioma atual do app).
    var localizedBundle: Bundle {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return Bundle.main
        }
        return bundle
    }

    /// Define o idioma do app (salvo nas configurações). A UI atualiza ao observar este objeto.
    func setLanguage(_ language: AppLanguage) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: StorageKeys.appLanguage)
    }

    /// Usa o idioma do sistema (e limpa a preferência salva).
    func useSystemLanguage() {
        let system = Self.languageFromSystem()
        if system != currentLanguage {
            currentLanguage = system
            UserDefaults.standard.removeObject(forKey: StorageKeys.appLanguage)
        }
    }

    /// Idioma salvo nas configurações (nil = usar sistema).
    static var storedAppLanguage: AppLanguage? {
        UserDefaults.standard.string(forKey: StorageKeys.appLanguage).flatMap { AppLanguage(rawValue: $0) }
    }

    private static func languageFromSystem() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("pt") { return .ptBR }
        if preferred.hasPrefix("fr") { return .fr }
        if preferred.hasPrefix("zh") { return .zhHans }
        return .en
    }
}

