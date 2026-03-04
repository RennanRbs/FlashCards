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
        .navigationTitle(L10n.card)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.edit) {
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
            Section(L10n.front) {
                Text(card.front)
                    .font(AppTypography.body)
            }
            Section(L10n.back) {
                Text(card.back)
                    .font(AppTypography.body)
            }
            Section(L10n.difficulty) {
                Text(L10n.difficultyName(card.difficulty))
                    .font(AppTypography.body)
            }
            if !card.tags.isEmpty {
                Section(L10n.tags) {
                    ForEach(card.tags, id: \.self) { tag in
                        TagChip(tag: tag, onRemove: nil)
                    }
                }
            }
            Section(L10n.statistics) {
                if let last = card.lastReviewedAt {
                    Label(last.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                }
                Label(L10n.successRateFormatted(Int(card.successRate * 100)), systemImage: "chart.bar")
            }
        }
    }

    private func fetchCard() {
        let descriptor = FetchDescriptor<Card>(predicate: #Predicate<Card> { $0.id == cardId })
        card = try? modelContext.fetch(descriptor).first
    }
}
