//
//  L10n.swift
//  FlashCards
//

import Foundation
internal import SwiftUI

/// Strings localizadas. Usa o idioma definido em AppLanguageManager (sistema ou escolhido nas configurações).
enum L10n {
    private static var bundle: Bundle {
        AppLanguageManager.shared.localizedBundle
    }

    static func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }

    // MARK: - General
    static var decks: String { string("decks") }
    static var deck: String { string("deck") }
    static var cancel: String { string("cancel") }
    static var save: String { string("save") }
    static var create: String { string("create") }
    static var edit: String { string("edit") }
    static var close: String { string("close") }
    static var done: String { string("done") }

    // MARK: - Decks list
    static var noDecksYet: String { string("no_decks_yet") }
    static var tapPlusToCreateFirst: String { string("tap_plus_to_create_first") }
    static var newDeck: String { string("new_deck") }
    static var deckNamePlaceholder: String { string("deck_name_placeholder") }
    static var cardsCountDominance: String { string("cards_count_dominance") }

    // MARK: - Generate cards (AI)
    static var generateCardsWithAI: String { string("generate_cards_with_ai") }
    static var generateCardsPromptPlaceholder: String { string("generate_cards_prompt_placeholder") }
    static var generateCardsPromptFooter: String { string("generate_cards_prompt_footer") }
    static var cardsQuantity: String { string("cards_quantity") }
    static var generate: String { string("generate") }
    static var aiUnavailableDevice: String { string("ai_unavailable_device") }
    static var aiUnavailableNotEnabled: String { string("ai_unavailable_not_enabled") }
    static var aiUnavailableModelNotReady: String { string("ai_unavailable_model_not_ready") }
    static var aiUnavailableOther: String { string("ai_unavailable_other") }
    static var errorTryFewerCards: String { string("error_try_fewer_cards") }
    static var errorCouldNotGenerate: String { string("error_could_not_generate") }

    // MARK: - Deck detail
    static var study: String { string("study") }
    static var noCardsInDeck: String { string("no_cards_in_deck") }
    static var tapPlusToAddCards: String { string("tap_plus_to_add_cards") }
    static var editDeck: String { string("edit_deck") }

    // MARK: - Card add/edit
    static var editCard: String { string("edit_card") }
    static var newCardTitle: String { string("new_card") }
    static var frontQuestion: String { string("front_question") }
    static var backAnswer: String { string("back_answer") }
    static var questionPlaceholder: String { string("question_placeholder") }
    static var answerPlaceholder: String { string("answer_placeholder") }
    static var tags: String { string("tags") }
    static var addTag: String { string("add_tag") }
    static var difficulty: String { string("difficulty") }
    static var important: String { string("important") }

    // MARK: - Difficulty
    static var difficultyLeve: String { string("difficulty_leve") }
    static var difficultyMedia: String { string("difficulty_media") }
    static var difficultyDificil: String { string("difficulty_dificil") }

    // MARK: - Card detail
    static var card: String { string("card") }
    static var front: String { string("front") }
    static var back: String { string("back") }
    static var statistics: String { string("statistics") }
    static var successRate: String { string("success_rate") }

    // MARK: - Study
    static var listen: String { string("listen") }
    static var noCardsToReview: String { string("no_cards_to_review") }
    static var sessionComplete: String { string("session_complete") }
    static var correctCount: String { string("correct_count") }
    static var incorrectCount: String { string("incorrect_count") }
    static var moveDeckToEnd: String { string("move_deck_to_end") }
    static var wrong: String { string("wrong") }
    static var hard: String { string("hard") }
    static var correct: String { string("correct") }

    // MARK: - Settings
    static var settings: String { string("settings") }
    static var account: String { string("account") }
    static var signOut: String { string("sign_out") }
    static var studySection: String { string("study_section") }
    static var reviewNotifications: String { string("review_notifications") }
    static var tts: String { string("tts") }
    static var data: String { string("data") }
    static var exportDecksJSON: String { string("export_decks_json") }
    static var importDecksJSON: String { string("import_decks_json") }
    static var importSuccess: String { string("import_success") }
    static var importErrorFile: String { string("import_error_file") }
    static var importErrorAccess: String { string("import_error_access") }
    static func importErrorGeneric(_ detail: String) -> String { String(format: string("import_error_generic"), detail) }
    static var language: String { string("language") }
    static var languageSystem: String { string("language_system") }

    // MARK: - Login
    static var appName: String { string("app_name") }
    static var appTagline: String { string("app_tagline") }
    static var continueWithoutLogin: String { string("continue_without_login") }
    static var dataStaysOnDevice: String { string("data_stays_on_device") }

    // MARK: - Statistics
    static var statisticsTitle: String { string("statistics_title") }
    static var overview: String { string("overview") }
    static var weeklyProgress: String { string("weekly_progress") }
    static var byDeck: String { string("by_deck") }
    static var statCorrect: String { string("stat_correct") }
    static var statStreak: String { string("stat_streak") }
    static var statStreakDays: String { string("stat_streak_days") }
    static var statStudied: String { string("stat_studied") }

    // MARK: - AI error (out of scope)
    static var aiErrorOutOfScope: String { string("ai_error_out_of_scope") }

    /// Nome localizado da dificuldade do card.
    static func difficultyName(_ d: CardDifficulty) -> String {
        switch d {
        case .leve: return difficultyLeve
        case .media: return difficultyMedia
        case .dificil: return difficultyDificil
        }
    }

    static func cardsCountDominanceFormatted(cards: Int, percent: Int) -> String {
        String(format: cardsCountDominance, cards, percent)
    }

    static func successRateFormatted(_ percent: Int) -> String {
        String(format: successRate, percent)
    }

    static func correctCountFormatted(_ count: Int) -> String {
        String(format: correctCount, count)
    }

    static func incorrectCountFormatted(_ count: Int) -> String {
        String(format: incorrectCount, count)
    }
}
