//
//  DecksListView.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData

struct DecksListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.orderIndex) private var decks: [Deck]
    @StateObject private var viewModel: DecksListViewModel
    @State private var showingAddDeck = false
    @State private var newDeckName = ""
    @State private var showingSettings = false
    @State private var showingStatistics = false

    init(modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DecksListViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()
                if decks.isEmpty {
                    emptyState
                } else {
                    deckList
                }
            }
            .navigationTitle("Decks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingStatistics = true
                    } label: {
                        Image(systemName: "chart.bar")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newDeckName = ""
                        showingAddDeck = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDeck) {
                addDeckSheet
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingStatistics) {
                StatisticsView()
            }
            .navigationDestination(for: UUID.self) { deckId in
                DeckDetailView(deckId: deckId)
            }
            .onAppear {
                DecksJSONService.seedFromBundleIfNeeded(context: modelContext)
                viewModel.fetchDecks()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Nenhum deck ainda")
                .font(AppTypography.title2)
            Text("Toque em + para criar seu primeiro deck.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var deckList: some View {
        List {
            ForEach(decks, id: \.id) { deck in
                NavigationLink(value: deck.id) {
                    DeckRowView(deck: deck)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: AppSpacing.xs, leading: AppSpacing.md, bottom: AppSpacing.xs, trailing: AppSpacing.md))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteDeck(decks[index])
                }
            }
            .onMove(perform: viewModel.moveDecks)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var addDeckSheet: some View {
        NavigationStack {
            Form {
                TextField("Nome do deck", text: $newDeckName)
            }
            .navigationTitle("Novo deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showingAddDeck = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar") {
                        let name = newDeckName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !name.isEmpty {
                            viewModel.addDeck(name: name)
                            showingAddDeck = false
                        }
                    }
                    .disabled(newDeckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct DeckRowView: View {
    let deck: Deck

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(deck.name)
                    .font(AppTypography.title2)
                Text("\(deck.cards.count) cards • \(Int(deck.dominancePercentage * 100))% dominado")
                    .font(AppTypography.subheadline)
                    .foregroundStyle(.secondary)
                ProgressBar(progress: deck.dominancePercentage)
                    .padding(.top, AppSpacing.xxs)
            }
        }
        .scaleEffect(1)
        .animation(.easeInOut(duration: 0.15), value: deck.id)
    }
}

#Preview {
    let schema = Schema([Deck.self, Card.self, StudySession.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return DecksListView(modelContext: container.mainContext)
}
