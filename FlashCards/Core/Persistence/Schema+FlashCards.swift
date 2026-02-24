//
//  Schema+FlashCards.swift
//  FlashCards
//

import SwiftData

enum FlashCardsSchema {
    static var schema: Schema {
        let modelTypes: [any PersistentModel.Type] = [Deck.self, Card.self, StudySession.self]
        return Schema(modelTypes)
    }
}
