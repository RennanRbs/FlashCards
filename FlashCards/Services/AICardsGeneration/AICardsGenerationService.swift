//
//  AICardsGenerationService.swift
//  FlashCards
//

import Foundation
import FoundationModels

// MARK: - Availability

enum AICardsGenerationAvailability {
    case available
    case unavailableDeviceNotEligible
    case unavailableAppleIntelligenceNotEnabled
    case unavailableModelNotReady
    case unavailableOther

    var canGenerate: Bool {
        if case .available = self { return true }
        return false
    }
}

// MARK: - Service

enum AICardsGenerationService {
    private static let model = SystemLanguageModel.default

    private static let instructions = """
    Você é um gerador de flashcards. Sua única tarefa é criar pares pergunta-resposta para estudo.
    Regras:
    - Escreva sempre em português brasileiro.
    - Para cada card use EXATAMENTE duas linhas no formato:
    FRONT: (a pergunta ou termo na frente do card)
    BACK: (a resposta ou definição no verso do card)
    - Não numere os cards. Não use markdown. Apenas FRONT: e BACK: em linhas separadas.
    - Gere conteúdo educativo, claro e correto.
    """

    /// Verifica se o modelo on-device está disponível para geração.
    static func checkAvailability() -> AICardsGenerationAvailability {
        switch model.availability {
        case .available:
            return .available
        case .unavailable(.deviceNotEligible):
            return .unavailableDeviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailableAppleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            return .unavailableModelNotReady
        case .unavailable:
            return .unavailableOther
        @unknown default:
            return .unavailableOther
        }
    }

    /// Gera uma lista de pares (frente, verso) para o tema e quantidade pedidos.
    /// - Parameters:
    ///   - userPrompt: Tema descrito pelo usuário (ex.: "cards de pokemon", "direito civil brasileiro").
    ///   - count: Número de cards desejado (recomendado limitar a 20–30).
    /// - Returns: Array de tuplas (front, back).
    static func generateCards(userPrompt: String, count: Int) async throws -> [(front: String, back: String)] {
        let session = LanguageModelSession(instructions: instructions)
        let promptText = """
        Tema: \(userPrompt)
        Gere exatamente \(count) flashcards sobre esse tema. Use apenas o formato:
        FRONT: pergunta
        BACK: resposta
        """
        let prompt = Prompt(promptText)
        let response = try await session.respond(to: prompt)
        let raw = response.content
        return parseCards(from: raw)
    }

    /// Extrai pares FRONT/BACK do texto retornado pelo modelo.
    private static func parseCards(from text: String) -> [(front: String, back: String)] {
        var result: [(front: String, back: String)] = []
        let lines = text.components(separatedBy: .newlines)
        var i = 0
        while i < lines.count {
            let line = lines[i]
            guard line.hasPrefix("FRONT:") else {
                i += 1
                continue
            }
            let front = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
            i += 1
            var back = ""
            while i < lines.count {
                let nextLine = lines[i]
                if nextLine.hasPrefix("BACK:") {
                    back = nextLine.dropFirst(5).trimmingCharacters(in: .whitespaces)
                    i += 1
                    break
                }
                if nextLine.hasPrefix("FRONT:") {
                    break
                }
                if !back.isEmpty { back += "\n" }
                back += nextLine.trimmingCharacters(in: .whitespaces)
                i += 1
            }
            if !front.isEmpty || !back.isEmpty {
                result.append((front: front.isEmpty ? " " : front, back: back.isEmpty ? " " : back))
            }
        }
        return result
    }

    /// Sugere um nome curto para o deck a partir do prompt do usuário.
    static func deckName(fromUserPrompt prompt: String) -> String {
        let t = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "Cards (IA)" }
        let maxLength = 40
        let collapsed = t.split(separator: " ").prefix(6).joined(separator: " ")
        let name = String(collapsed)
        if name.count > maxLength {
            return String(name.prefix(maxLength)).trimmingCharacters(in: .whitespaces) + "…"
        }
        return name.isEmpty ? "Cards (IA)" : "\(name) (IA)"
    }
}
