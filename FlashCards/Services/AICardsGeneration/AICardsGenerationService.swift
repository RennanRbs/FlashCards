//
//  AICardsGenerationService.swift
//  FlashCards
//

import Foundation
import FoundationModels

// MARK: - Errors

enum AICardsGenerationError: LocalizedError {
    case outOfScope

    var errorDescription: String? {
        switch self {
        case .outOfScope:
            return L10n.aiErrorOutOfScope
        }
    }
}

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
    Você é um gerador de flashcards para pessoas da área de tecnologia. Aceite qualquer tema de:
    PROGRAMAÇÃO: qualquer linguagem de programação (C#, COBOL, Java, Python, Swift, JavaScript, Go, Rust, etc.),
    incluindo tópicos específicos da linguagem: alocação de memória, sintaxe, tipos, frameworks, APIs, boas práticas,
    estruturas de dados, algoritmos, padrões de projeto, entrevistas de TI, DevOps, testes, banco de dados.
    DESIGN: Design Thinking, design para web, design para Android, design para iOS, design de interfaces (UX/UI),
    botões e componentes em aplicativos, acessibilidade, metodologias de design, design de software.
    GESTÃO E PROCESSO: agilidade (Scrum, Kanban), PO (Product Owner), PMO.
    Recuse APENAS temas claramente fora desse escopo (ex.: pokémon, direito civil, história geral, geografia, etc.).
    Regras:
    - Escreva sempre em português brasileiro.
    - Se o tema pedido NÃO for programação, design ou gestão de TI (ex.: entretenimento, direito, ciências humanas, etc.),
      responda com exatamente esta linha, sem mais nada: OUT_OF_SCOPE
    - Para cada card use exatamente três linhas no formato:
    FRONT: (a pergunta ou termo na frente do card)
    BACK: (a resposta ou definição no verso do card)
    DIFFICULTY: leve OU media OU dificil
    - Não numere os cards. Não use markdown. Use apenas FRONT:, BACK: e DIFFICULTY: em linhas separadas.
    - DIFFICULTY deve ser uma única palavra: leve (fácil), media (intermediário) ou dificil (avançado). Escolha conforme a complexidade do conteúdo.
    - Gere conteúdo educativo, claro e correto para estudo e preparação para entrevistas.
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

    /// Gera uma lista de cards (frente, verso, dificuldade) para o tema e quantidade pedidos.
    /// Aceita apenas temas de programação, entrevistas, agilidade, PO, PMO, design e correlatos.
    /// - Parameters:
    ///   - userPrompt: Tema descrito pelo usuário (ex.: "Core Data em Swift", "Design Thinking", "entrevistas backend").
    ///   - count: Número de cards desejado (recomendado limitar a 20–30).
    /// - Returns: Array de tuplas (front, back, difficulty).
    /// - Throws: AICardsGenerationError.outOfScope se o tema estiver fora do escopo do app.
    static func generateCards(userPrompt: String, count: Int) async throws -> [(front: String, back: String, difficulty: CardDifficulty)] {
        let session = LanguageModelSession(instructions: instructions)
        let promptText = """
        Tema: \(userPrompt)
        Gere exatamente \(count) flashcards sobre esse tema. Aceite se for sobre qualquer linguagem de programação (ex.: C#, COBOL, alocação de memória), design (Design Thinking, web, Android, botões em apps) ou gestão de TI. Para cada card use o formato:
        FRONT: pergunta
        BACK: resposta
        DIFFICULTY: leve ou media ou dificil
        """
        let prompt = Prompt(promptText)
        let response = try await session.respond(to: prompt)
        let raw = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.uppercased().hasPrefix("OUT_OF_SCOPE") || raw == "OUT_OF_SCOPE" {
            throw AICardsGenerationError.outOfScope
        }
        return parseCardsWithDifficulty(from: response.content)
    }

    /// Extrai pares FRONT/BACK/DIFFICULTY do texto retornado pelo modelo.
    private static func parseCardsWithDifficulty(from text: String) -> [(front: String, back: String, difficulty: CardDifficulty)] {
        var result: [(front: String, back: String, difficulty: CardDifficulty)] = []
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
            var difficulty: CardDifficulty = .media
            if i < lines.count, lines[i].uppercased().hasPrefix("DIFFICULTY:") {
                let diffLine = lines[i].dropFirst(11).trimmingCharacters(in: .whitespaces).lowercased()
                i += 1
                if diffLine == "leve" { difficulty = .leve }
                else if diffLine == "dificil" || diffLine == "difícil" { difficulty = .dificil }
                else { difficulty = .media }
            }
            if !front.isEmpty || !back.isEmpty {
                result.append((front: front.isEmpty ? " " : front, back: back.isEmpty ? " " : back, difficulty: difficulty))
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
