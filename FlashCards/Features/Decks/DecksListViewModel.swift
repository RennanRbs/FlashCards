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

    func addDeck(name: String) {
        let maxIndex = decks.map(\.orderIndex).max() ?? -1
        let deck = Deck(name: name, orderIndex: maxIndex + 1)
        modelContext.insert(deck)
        try? modelContext.save()
        DecksJSONService.appendDeck(id: deck.id, name: deck.name, orderIndex: deck.orderIndex)
        fetchDecks()
    }

    func updateDeck(_ deck: Deck, name: String) {
        deck.name = name
        deck.updatedAt = Date()
        try? modelContext.save()
        fetchDecks()
    }
}
