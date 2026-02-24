//
//  SRSServiceTests.swift
//  FlashCardsTests
//

import XCTest
import SwiftData
@testable import FlashCards

final class SRSServiceTests: XCTestCase {

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

    func testRecordIncorrectDecreasesEaseFactor() throws {
        let deck = Deck(name: "Test", orderIndex: 0)
        modelContext.insert(deck)
        let card = Card(front: "Q", back: "A", deck: deck)
        let initialEase = card.easeFactor
        modelContext.insert(card)
        try modelContext.save()

        let srs = SRSService(modelContext: modelContext)
        srs.recordResult(.incorrect, for: card)

        XCTAssertLessThan(card.easeFactor, initialEase)
        XCTAssertEqual(card.totalIncorrect, 1)
        XCTAssertEqual(card.consecutiveCorrect, 0)
    }

    func testRecordCorrectIncreasesInterval() throws {
        let deck = Deck(name: "Test", orderIndex: 0)
        modelContext.insert(deck)
        let card = Card(front: "Q", back: "A", deck: deck)
        let initialInterval = card.intervalDays
        modelContext.insert(card)
        try modelContext.save()

        let srs = SRSService(modelContext: modelContext)
        srs.recordResult(.correct, for: card)

        XCTAssertGreaterThanOrEqual(card.intervalDays, initialInterval)
        XCTAssertEqual(card.totalCorrect, 1)
        XCTAssertNotNil(card.nextReviewDate)
    }

    func testQueueForStudyOrdersByNextReviewDate() throws {
        let deck = Deck(name: "Test", orderIndex: 0)
        modelContext.insert(deck)
        let now = Date()
        let past = now.addingTimeInterval(-3600)
        let future = now.addingTimeInterval(3600)
        let card1 = Card(front: "1", back: "1", deck: deck)
        card1.nextReviewDate = future
        let card2 = Card(front: "2", back: "2", deck: deck)
        card2.nextReviewDate = past
        modelContext.insert(card1)
        modelContext.insert(card2)
        try modelContext.save()

        let queue = SRSService.queueForStudy(from: [card1, card2], limit: 10)
        XCTAssertEqual(queue.count, 2)
        XCTAssertEqual(queue.first?.id, card2.id)
    }
}
