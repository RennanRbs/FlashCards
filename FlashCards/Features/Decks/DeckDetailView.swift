//
//  DeckDetailView.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData

struct DeckDetailView: View {
    let deckId: UUID
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var deck: Deck?
    @State private var showingStudy = false
    @State private var showingAddCard = false
    @State private var showingEditDeck = false
    @State private var editDeckName = ""

    var body: some View {
        Group {
            if let deck = deck {
                deckContent(deck)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(deck?.name ?? "Deck")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") {
                    editDeckName = deck?.name ?? ""
                    showingEditDeck = true
                }
            }
        }
        .onAppear {
            fetchDeck()
        }
        .fullScreenCover(isPresented: $showingStudy) {
            if let deck = deck {
                StudyView(deck: deck)
            }
        }
        .sheet(isPresented: $showingAddCard) {
            if let deck = deck {
                AddEditCardView(deck: deck, card: nil)
            }
        }
        .sheet(isPresented: $showingEditDeck) {
            if let deck = deck {
                editDeckSheet(deck)
            }
        }
        .navigationDestination(for: CardId.self) { cardId in
            CardDetailView(cardId: cardId.id)
        }
    }

    private func deckContent(_ deck: Deck) -> some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            VStack(spacing: AppSpacing.lg) {
                if deck.cards.isEmpty {
                    emptyCardsState
                } else {
                    cardsList(deck)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton("Estudar", style: .primary) {
                HapticsManager.medium()
                showingStudy = true
            }
            .padding(.horizontal)
            .padding(.vertical, AppSpacing.sm)
            .background(Color("BackgroundColor"))
        }
    }

    private var emptyCardsState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Nenhum card neste deck")
                .font(AppTypography.title2)
            Text("Toque em + para adicionar cards.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func cardsList(_ deck: Deck) -> some View {
        List {
            ForEach(deck.sortedCards, id: \.id) { card in
                NavigationLink(value: CardId(id: card.id)) {
                    CardRowView(card: card)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
            }
            .onDelete { indexSet in
                deleteCards(from: deck, at: indexSet)
            }
            .onMove { source, dest in
                moveCards(deck: deck, from: source, to: dest)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func editDeckSheet(_ deck: Deck) -> some View {
        NavigationStack {
            Form {
                TextField("Nome do deck", text: $editDeckName)
            }
            .navigationTitle("Editar deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showingEditDeck = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        let name = editDeckName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty {
                            deck.name = name
                            deck.updatedAt = Date()
                            try? modelContext.save()
                            showingEditDeck = false
                            fetchDeck()
                        }
                    }
                    .disabled(editDeckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func fetchDeck() {
        let descriptor = FetchDescriptor<Deck>(predicate: #Predicate<Deck> { $0.id == deckId })
        deck = try? modelContext.fetch(descriptor).first
    }

    private func deleteCards(from deck: Deck, at indexSet: IndexSet) {
        let sorted = deck.sortedCards
        for index in indexSet {
            modelContext.delete(sorted[index])
        }
        try? modelContext.save()
        fetchDeck()
    }

    private func moveCards(deck: Deck, from source: IndexSet, to destination: Int) {
        var sorted = deck.sortedCards
        sorted.move(fromOffsets: source, toOffset: destination)
        for (i, card) in sorted.enumerated() {
            card.orderIndex = i
        }
        try? modelContext.save()
        fetchDeck()
    }
}

struct CardRowView: View {
    let card: Card

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(card.front)
                    .font(AppTypography.bodyMedium)
                    .lineLimit(2)
                if !card.tags.isEmpty {
                    HStack(spacing: AppSpacing.xxs) {
                        ForEach(card.tags, id: \.self) { tag in
                            TagChip(tag: tag, onRemove: nil)
                        }
                    }
                }
            }
        }
    }
}
