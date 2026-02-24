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

    var isEditing: Bool { card != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Frente (pergunta)") {
                    TextField("Pergunta", text: $front, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Verso (resposta)") {
                    TextField("Resposta", text: $back, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Tags") {
                    HStack {
                        TextField("Nova tag", text: $tagInput)
                            .onSubmit {
                                addTag()
                            }
                        Button("Adicionar") {
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
                Section {
                    Toggle("Importante", isOn: $isImportant)
                }
            }
            .navigationTitle(isEditing ? "Editar card" : "Novo card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
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
            card.updatedAt = Date()
        } else {
            let maxIndex = deck.sortedCards.map(\.orderIndex).max() ?? -1
            let newCard = Card(
                front: f,
                back: b,
                tags: tags,
                isImportant: isImportant,
                orderIndex: maxIndex + 1,
                deck: deck
            )
            modelContext.insert(newCard)
            DecksJSONService.appendCard(deckId: deck.id, front: f, back: b, tags: tags)
        }
        try? modelContext.save()
        dismiss()
    }
}
