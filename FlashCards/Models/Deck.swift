//
//  Deck.swift
//  FlashCards
//

import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var orderIndex: Int

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        orderIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.orderIndex = orderIndex
    }

    var sortedCards: [Card] {
        cards.sorted { $0.orderIndex < $1.orderIndex }
    }

    /// Dominance percentage (0...1) based on card success rates
    var dominancePercentage: Double {
        let total = cards.count
        guard total > 0 else { return 0 }
        let totalCorrect = cards.reduce(0) { $0 + $1.totalCorrect }
        let totalIncorrect = cards.reduce(0) { $0 + $1.totalIncorrect }
        let totalReviews = totalCorrect + totalIncorrect
        guard totalReviews > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalReviews)
    }
}
