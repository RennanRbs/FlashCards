//
//  WidgetDataStore.swift
//  FlashCards
//
//  Shared with Widget via App Group. Write from main app; widget reads.
//

import Foundation

enum WidgetDataStore {
    static let appGroupID = "group.rennanRBS.FlashCards"

    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func write(lastDeckName: String?, cardsStudiedThisWeek: Int, streakDays: Int) {
        userDefaults?.set(lastDeckName, forKey: "lastDeckName")
        userDefaults?.set(cardsStudiedThisWeek, forKey: "cardsStudiedThisWeek")
        userDefaults?.set(streakDays, forKey: "streakDays")
        userDefaults?.synchronize()
    }

    static func lastDeckName() -> String? {
        userDefaults?.string(forKey: "lastDeckName")
    }

    static func cardsStudiedThisWeek() -> Int {
        userDefaults?.integer(forKey: "cardsStudiedThisWeek") ?? 0
    }

    static func streakDays() -> Int {
        userDefaults?.integer(forKey: "streakDays") ?? 0
    }
}
