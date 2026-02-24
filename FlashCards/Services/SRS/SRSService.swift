//
//  SRSService.swift
//  FlashCards
//

import Foundation
import SwiftData

enum StudyResult {
    case incorrect
    case hard
    case correct
}

final class SRSService {
    private let modelContext: ModelContext

    /// Base interval in days for correct answers
    private let baseIntervalDays: Double = 1
    /// Minimum ease factor
    private let minEaseFactor: Double = 1.3
    /// Ease factor increment per correct
    private let easeIncrement: Double = 0.1

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Applies the study result to the card and updates SRS fields.
    func recordResult(_ result: StudyResult, for card: Card) {
        let now = Date()
        card.lastReviewedAt = now

        switch result {
        case .incorrect:
            card.totalIncorrect += 1
            card.consecutiveCorrect = 0
            card.easeFactor = max(minEaseFactor, card.easeFactor - 0.2)
            card.intervalDays = 0.25 // ~6 hours, reappear soon
            card.nextReviewDate = now.addingTimeInterval(6 * 60 * 60)

        case .hard:
            card.totalCorrect += 1
            card.consecutiveCorrect += 1
            card.intervalDays = max(0.5, card.intervalDays * 0.8)
            card.nextReviewDate = now.addingTimeInterval(card.intervalDays * 24 * 60 * 60)

        case .correct:
            card.totalCorrect += 1
            card.consecutiveCorrect += 1
            card.easeFactor = min(3.0, card.easeFactor + easeIncrement * 0.1)
            card.intervalDays = max(baseIntervalDays, card.intervalDays * card.easeFactor)
            card.nextReviewDate = now.addingTimeInterval(card.intervalDays * 24 * 60 * 60)
        }

        card.updatedAt = now
        try? modelContext.save()
    }

    /// Returns cards to study for this deck: due first, then by most incorrect.
    static func queueForStudy(from cards: [Card], limit: Int = 50) -> [Card] {
        let now = Date()
        let sorted = cards.sorted { c1, c2 in
            let due1 = c1.nextReviewDate ?? .distantPast
            let due2 = c2.nextReviewDate ?? .distantPast
            if due1 <= now && due2 > now { return true }
            if due1 > now && due2 <= now { return false }
            if due1 != due2 { return due1 < due2 }
            return c1.totalIncorrect > c2.totalIncorrect
        }
        return Array(sorted.prefix(limit))
    }
}
