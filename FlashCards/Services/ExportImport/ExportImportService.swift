//
//  ExportImportService.swift
//  FlashCards
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

struct DeckExport: Codable {
    let id: UUID
    let name: String
    let createdAt: Date
    let orderIndex: Int
    let cards: [CardExport]
}

struct CardExport: Codable {
    let id: UUID
    let front: String
    let back: String
    let tags: [String]
    let isImportant: Bool
    let orderIndex: Int
}

enum ExportImportService {
    static func exportDecks(_ decks: [Deck]) -> Data? {
        let payload = decks.map { deck in
            DeckExport(
                id: deck.id,
                name: deck.name,
                createdAt: deck.createdAt,
                orderIndex: deck.orderIndex,
                cards: deck.sortedCards.map { card in
                    CardExport(
                        id: card.id,
                        front: card.front,
                        back: card.back,
                        tags: card.tags,
                        isImportant: card.isImportant,
                        orderIndex: card.orderIndex
                    )
                }
            )
        }
        return try? JSONEncoder().encode(payload)
    }

    static func importDecks(from data: Data, into context: ModelContext) throws -> Int {
        let payload = try JSONDecoder().decode([DeckExport].self, from: data)
        var count = 0
        for d in payload {
            let deck = Deck(
                name: d.name,
                createdAt: d.createdAt,
                updatedAt: Date(),
                orderIndex: d.orderIndex
            )
            context.insert(deck)
            for (idx, c) in d.cards.enumerated() {
                let card = Card(
                    front: c.front,
                    back: c.back,
                    tags: c.tags,
                    isImportant: c.isImportant,
                    orderIndex: c.orderIndex,
                    deck: deck
                )
                context.insert(card)
                count += 1
            }
            count += 1
        }
        try context.save()
        return count
    }
}
