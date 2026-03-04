//
//  DecksListViewModel.swift
//  FlashCards
//

import Foundation
import SwiftData
internal import Combine
internal import SwiftUI

@MainActor
final class DecksListViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.decks = []
        self.modelContext = modelContext
    }

    func fetchDecks() {
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.orderIndex)])
        decks = (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteDeck(_ deck: Deck) {
        modelContext.delete(deck)
        try? modelContext.save()
        fetchDecks()
    }

    func moveDecks(from source: IndexSet, to destination: Int) {
        var reordered = decks
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, deck) in reordered.enumerated() {
            deck.orderIndex = index
        }
        try? modelContext.save()
        fetchDecks()
    }

    /// Adiciona um novo deck no topo da lista.
    func addDeck(name: String) {
        let deck = Deck(name: name, orderIndex: 0)
        modelContext.insert(deck)
        for d in decks {
            d.orderIndex += 1
        }
        try? modelContext.save()
        DecksJSONService.appendDeck(id: deck.id, name: deck.name, orderIndex: 0)
        fetchDecks()
    }

    func updateDeck(_ deck: Deck, name: String) {
        deck.name = name
        deck.updatedAt = Date()
        try? modelContext.save()
        fetchDecks()
    }

    /// Move o deck para o fim da fila (maior orderIndex) na lista da página inicial.
    func moveDeckToEnd(_ deck: Deck) {
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.orderIndex)])
        guard var all = try? modelContext.fetch(descriptor),
              let idx = all.firstIndex(where: { $0.id == deck.id }) else { return }
        let d = all.remove(at: idx)
        all.append(d)
        for (i, deck) in all.enumerated() {
            deck.orderIndex = i
        }
        try? modelContext.save()
        fetchDecks()
    }
}
