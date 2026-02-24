//
//  ExportImportServiceTests.swift
//  FlashCardsTests
//

import XCTest
import SwiftData
@testable import FlashCards

final class ExportImportServiceTests: XCTestCase {

    var modelContext: ModelContext!
    var container: ModelContainer!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Deck.self, Card.self, StudySession.self, configurations: config)
        modelContext = ModelContext(container)
    }

    override func tearDown() async throws {
        modelContext = nil
        container = nil
    }

    func testExportDecksEncodesToJSON() throws {
        let deck = Deck(name: "My Deck", orderIndex: 0)
        modelContext.insert(deck)
        let card = Card(front: "Q", back: "A", tags: ["tag1"], deck: deck)
        modelContext.insert(card)
        try modelContext.save()

        let data = ExportImportService.exportDecks([deck])
        XCTAssertNotNil(data)
        let decoded = try JSONDecoder().decode([DeckExport].self, from: data!)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].name, "My Deck")
        XCTAssertEqual(decoded[0].cards.count, 1)
        XCTAssertEqual(decoded[0].cards[0].front, "Q")
        XCTAssertEqual(decoded[0].cards[0].tags, ["tag1"])
    }

    func testImportDecksCreatesModels() throws {
        let payload = [
            DeckExport(
                id: UUID(),
                name: "Imported",
                createdAt: Date(),
                orderIndex: 0,
                cards: [
                    CardExport(id: UUID(), front: "F", back: "B", tags: [], isImportant: false, orderIndex: 0)
                ]
            )
        ]
        let data = try JSONEncoder().encode(payload)
        let count = try ExportImportService.importDecks(from: data, into: modelContext)
        XCTAssertGreaterThan(count, 0)
        let descriptor = FetchDescriptor<Deck>()
        let decks = try modelContext.fetch(descriptor)
        XCTAssertEqual(decks.count, 1)
        XCTAssertEqual(decks[0].name, "Imported")
        XCTAssertEqual(decks[0].cards.count, 1)
        XCTAssertEqual(decks[0].cards[0].front, "F")
    }
}
