//
//  Card.swift
//  FlashCards
//

import Foundation
import SwiftData

/// Dificuldade do card para estudo (leve, média, difícil).
enum CardDifficulty: Int, CaseIterable, Codable {
    case leve = 0
    case media = 1
    case dificil = 2

    var displayName: String {
        switch self {
        case .leve: return "Leve"
        case .media: return "Média"
        case .dificil: return "Difícil"
        }
    }
}

@Model
final class Card {
    var id: UUID
    var front: String
    var back: String
    var tagsString: String // comma-separated for persistence
    var imageData: Data?
    var audioURL: String?
    var isImportant: Bool
    /// 0 = leve, 1 = média, 2 = difícil (default 1 para compatibilidade com dados antigos).
    var difficultyRawValue: Int = 1
    var orderIndex: Int
    var createdAt: Date
    var updatedAt: Date

    // SRS fields
    var easeFactor: Double
    var intervalDays: Double
    var nextReviewDate: Date?
    var lastReviewedAt: Date?
    var consecutiveCorrect: Int
    var totalCorrect: Int
    var totalIncorrect: Int

    var deck: Deck?

    var difficulty: CardDifficulty {
        get { CardDifficulty(rawValue: difficultyRawValue) ?? .media }
        set { difficultyRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        tags: [String] = [],
        imageData: Data? = nil,
        audioURL: String? = nil,
        isImportant: Bool = false,
        difficulty: CardDifficulty = .media,
        orderIndex: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        easeFactor: Double = 2.5,
        intervalDays: Double = 1,
        nextReviewDate: Date? = nil,
        lastReviewedAt: Date? = nil,
        consecutiveCorrect: Int = 0,
        totalCorrect: Int = 0,
        totalIncorrect: Int = 0,
        deck: Deck? = nil
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.tagsString = tags.joined(separator: ",")
        self.imageData = imageData
        self.audioURL = audioURL
        self.isImportant = isImportant
        self.difficultyRawValue = difficulty.rawValue
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.nextReviewDate = nextReviewDate
        self.lastReviewedAt = lastReviewedAt
        self.consecutiveCorrect = consecutiveCorrect
        self.totalCorrect = totalCorrect
        self.totalIncorrect = totalIncorrect
        self.deck = deck
    }

    var tags: [String] {
        get {
            guard !tagsString.isEmpty else { return [] }
            return tagsString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        set {
            tagsString = newValue.joined(separator: ",")
        }
    }

    var successRate: Double {
        let total = totalCorrect + totalIncorrect
        guard total > 0 else { return 0 }
        return Double(totalCorrect) / Double(total)
    }
}
