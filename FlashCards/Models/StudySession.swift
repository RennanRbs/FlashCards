//
//  StudySession.swift
//  FlashCards
//

import Foundation
import SwiftData

@Model
final class StudySession {
    var id: UUID
    var deckId: UUID
    var userId: String?
    var startedAt: Date
    var endedAt: Date?
    var correctCount: Int
    var incorrectCount: Int
    var cardsSeen: Int

    init(
        id: UUID = UUID(),
        deckId: UUID,
        userId: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        cardsSeen: Int = 0
    ) {
        self.id = id
        self.deckId = deckId
        self.userId = userId
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.cardsSeen = cardsSeen
    }

    var duration: TimeInterval? {
        guard let end = endedAt else { return nil }
        return end.timeIntervalSince(startedAt)
    }
}
