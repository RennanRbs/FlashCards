//
//  CardDetailView.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData

struct CardDetailView: View {
    let cardId: UUID
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var card: Card?
    @State private var showingEdit = false

    var body: some View {
        Group {
            if let card = card {
                cardContent(card)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") {
                    showingEdit = true
                }
            }
        }
        .onAppear {
            fetchCard()
        }
        .sheet(isPresented: $showingEdit) {
            if let card = card, let deck = card.deck {
                AddEditCardView(deck: deck, card: card)
                    .onDisappear {
                        fetchCard()
                    }
            }
        }
    }

    private func cardContent(_ card: Card) -> some View {
        List {
            Section("Frente") {
                Text(card.front)
                    .font(AppTypography.body)
            }
            Section("Verso") {
                Text(card.back)
                    .font(AppTypography.body)
            }
            if !card.tags.isEmpty {
                Section("Tags") {
                    ForEach(card.tags, id: \.self) { tag in
                        TagChip(tag: tag, onRemove: nil)
                    }
                }
            }
            Section("Estatísticas") {
                if let last = card.lastReviewedAt {
                    Label(last.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                }
                Label("\(Int(card.successRate * 100))% acertos", systemImage: "chart.bar")
            }
        }
    }

    private func fetchCard() {
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate<Card> { $0.id == cardId })
        card = try? modelContext.fetch(descriptor).first
    }
}
