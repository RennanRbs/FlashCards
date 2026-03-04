//
//  AddEditCardView.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData

struct AddEditCardView: View {
    let deck: Deck
    let card: Card?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var front = ""
    @State private var back = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var isImportant = false
    @State private var difficulty: CardDifficulty = .media

    var isEditing: Bool { card != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.frontQuestion) {
                    TextField(L10n.questionPlaceholder, text: $front, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section(L10n.backAnswer) {
                    TextField(L10n.answerPlaceholder, text: $back, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section(L10n.tags) {
                    HStack {
                        TextField(L10n.tags, text: $tagInput)
                            .onSubmit {
                                addTag()
                            }
                        Button(L10n.addTag) {
                            addTag()
                        }
                        .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if !tags.isEmpty {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(tag: tag) {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }
                }
                Section(L10n.difficulty) {
                    Picker(L10n.difficulty, selection: $difficulty) {
                        ForEach(CardDifficulty.allCases, id: \.self) { d in
                            Text(L10n.difficultyName(d)).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section {
                    Toggle(L10n.important, isOn: $isImportant)
                }
            }
            .navigationTitle(isEditing ? L10n.editCard : L10n.newCardTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        save()
                    }
                    .disabled(front.trimmingCharacters(in: .whitespaces).isEmpty || back.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let card = card {
                    front = card.front
                    back = card.back
                    tags = card.tags
                    isImportant = card.isImportant
                    difficulty = card.difficulty
                }
            }
        }
    }

    private func addTag() {
        let t = tagInput.trimmingCharacters(in: .whitespaces).lowercased()
        guard !t.isEmpty, !tags.contains(t) else { return }
        tags.append(t)
        tagInput = ""
    }

    private func save() {
        let f = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !b.isEmpty else { return }
        if var card = card {
            card.front = f
            card.back = b
            card.tags = tags
            card.isImportant = isImportant
            card.difficulty = difficulty
            card.updatedAt = Date()
        } else {
            let maxIndex = deck.sortedCards.map(\.orderIndex).max() ?? -1
            let newCard = Card(
                front: f,
                back: b,
                tags: tags,
                isImportant: isImportant,
                difficulty: difficulty,
                orderIndex: maxIndex + 1,
                deck: deck
            )
            modelContext.insert(newCard)
            DecksJSONService.appendCard(deckId: deck.id, front: f, back: b, tags: tags, difficulty: difficulty)
        }
        try? modelContext.save()
        dismiss()
    }
}
