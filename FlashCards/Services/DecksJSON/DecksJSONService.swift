//
//  DecksJSONService.swift
//  FlashCards
//

import Foundation
import SwiftData

// MARK: - JSON DTOs

struct DecksJSON: Codable {
    var decks: [DeckJSON]
}

struct DeckJSON: Codable {
    var id: String?
    var name: String
    var orderIndex: Int
    var cards: [CardJSON]
}

struct CardJSON: Codable {
    var front: String
    var back: String
    var tags: [String]?
}

// MARK: - Service

enum DecksJSONService {
    private static let bundledFileName = "decks_programming"
    private static let bundledFileExtension = "json"
    private static let documentsFileName = "decks_data.json"

    /// URL do JSON no bundle (recurso inicial).
    static var bundledURL: URL? {
        Bundle.main.url(forResource: bundledFileName, withExtension: bundledFileExtension, subdirectory: "Resources")
            ?? Bundle.main.url(forResource: bundledFileName, withExtension: bundledFileExtension)
    }

    /// URL do JSON em Documents (incrementado com decks/cards do usuário).
    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(documentsFileName)
    }

    /// Carrega o JSON do bundle (recurso inicial).
    static func loadBundled() -> DecksJSON? {
        guard let url = bundledURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DecksJSON.self, from: data)
    }

    /// Carrega o JSON de Documents (dados incrementados).
    static func loadFromDocuments() -> DecksJSON? {
        let url = documentsURL
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(DecksJSON.self, from: data)
    }

    /// Salva o JSON em Documents.
    static func saveToDocuments(_ payload: DecksJSON) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: documentsURL)
    }

    /// Importa o conteúdo do JSON (bundle ou Documents) para o SwiftData. Não insere decks que já existem (por id).
    @MainActor
    static func importIntoSwiftData(context: ModelContext, payload: DecksJSON) {
        for deckJSON in payload.decks {
            let deckId = UUID(uuidString: deckJSON.id ?? "") ?? UUID()
            let descriptor = FetchDescriptor<Deck>(predicate: #Predicate<Deck> { $0.id == deckId })
            let existing = (try? context.fetch(descriptor))?.first
            if existing != nil { continue }
            let deck = Deck(
                id: deckId,
                name: deckJSON.name,
                orderIndex: deckJSON.orderIndex
            )
            context.insert(deck)
            for (cardIndex, cardJSON) in deckJSON.cards.enumerated() {
                let card = Card(
                    front: cardJSON.front,
                    back: cardJSON.back,
                    tags: cardJSON.tags ?? [],
                    orderIndex: cardIndex,
                    deck: deck
                )
                context.insert(card)
            }
        }
        try? context.save()
    }

    /// Garante que o JSON em Documents existe (cópia do bundle na primeira vez) e importa para SwiftData se necessário.
    @MainActor
    static func seedFromBundleIfNeeded(context: ModelContext) {
        if let existing = loadFromDocuments() {
            importIntoSwiftData(context: context, payload: existing)
            return
        }
        guard let bundled = loadBundled() else { return }
        var payloadWithIds = bundled
        for (deckIndex, deckJSON) in payloadWithIds.decks.enumerated() {
            let deckId = UUID()
            payloadWithIds.decks[deckIndex].id = deckId.uuidString
            let deck = Deck(
                id: deckId,
                name: deckJSON.name,
                orderIndex: deckJSON.orderIndex
            )
            context.insert(deck)
            for (cardIndex, cardJSON) in deckJSON.cards.enumerated() {
                let card = Card(
                    front: cardJSON.front,
                    back: cardJSON.back,
                    tags: cardJSON.tags ?? [],
                    orderIndex: cardIndex,
                    deck: deck
                )
                context.insert(card)
            }
        }
        try? context.save()
        saveToDocuments(payloadWithIds)
    }

    /// Adiciona um deck ao JSON em Documents (incremento quando o usuário cria um deck).
    static func appendDeck(id: UUID, name: String, orderIndex: Int) {
        var payload = loadFromDocuments() ?? DecksJSON(decks: [])
        payload.decks.append(DeckJSON(id: id.uuidString, name: name, orderIndex: orderIndex, cards: []))
        saveToDocuments(payload)
    }

    /// Adiciona um card ao deck no JSON em Documents (incremento quando o usuário cria um card).
    static func appendCard(deckId: UUID, front: String, back: String, tags: [String]) {
        var payload = loadFromDocuments() ?? DecksJSON(decks: [])
        guard let index = payload.decks.firstIndex(where: { $0.id == deckId.uuidString }) else { return }
        payload.decks[index].cards.append(CardJSON(front: front, back: back, tags: tags.isEmpty ? nil : tags))
        saveToDocuments(payload)
    }
}
