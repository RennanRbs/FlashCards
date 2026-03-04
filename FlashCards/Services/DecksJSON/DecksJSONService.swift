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
    /// "leve", "media" ou "dificil" (opcional para compatibilidade).
    var difficulty: String?
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
                let difficulty = Self.parseDifficulty(cardJSON.difficulty)
                let card = Card(
                    front: cardJSON.front,
                    back: cardJSON.back,
                    tags: cardJSON.tags ?? [],
                    difficulty: difficulty,
                    orderIndex: cardIndex,
                    deck: deck
                )
                context.insert(card)
            }
        }
        try? context.save()
    }

    private static func parseDifficulty(_ raw: String?) -> CardDifficulty {
        guard let raw = raw?.lowercased() else { return .media }
        switch raw {
        case "leve": return .leve
        case "dificil", "difícil": return .dificil
        default: return .media
        }
    }

    /// Garante que o JSON em Documents existe. Se já existir, importa para SwiftData. Na primeira vez, inicia vazio (sem conteúdo do bundle).
    @MainActor
    static func seedFromBundleIfNeeded(context: ModelContext) {
        if let existing = loadFromDocuments() {
            importIntoSwiftData(context: context, payload: existing)
            return
        }
        saveToDocuments(DecksJSON(decks: []))
    }

    /// Adiciona um deck ao JSON em Documents. Se orderIndex for 0, o deck vai para o topo e os demais são deslocados.
    static func appendDeck(id: UUID, name: String, orderIndex: Int) {
        var payload = loadFromDocuments() ?? DecksJSON(decks: [])
        if orderIndex == 0 {
            for i in payload.decks.indices {
                payload.decks[i].orderIndex += 1
            }
            payload.decks.insert(DeckJSON(id: id.uuidString, name: name, orderIndex: 0, cards: []), at: 0)
        } else {
            payload.decks.append(DeckJSON(id: id.uuidString, name: name, orderIndex: orderIndex, cards: []))
        }
        saveToDocuments(payload)
    }

    /// Adiciona um card ao deck no JSON em Documents (incremento quando o usuário cria um card).
    static func appendCard(deckId: UUID, front: String, back: String, tags: [String], difficulty: CardDifficulty = .media) {
        var payload = loadFromDocuments() ?? DecksJSON(decks: [])
        guard let index = payload.decks.firstIndex(where: { $0.id == deckId.uuidString }) else { return }
        let difficultyString = difficultyString(from: difficulty)
        payload.decks[index].cards.append(CardJSON(front: front, back: back, tags: tags.isEmpty ? nil : tags, difficulty: difficultyString))
        saveToDocuments(payload)
    }

    private static func difficultyString(from d: CardDifficulty) -> String {
        switch d {
        case .leve: return "leve"
        case .media: return "media"
        case .dificil: return "dificil"
        }
    }
}
