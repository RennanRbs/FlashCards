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
    @State private var showingGenerateCards = false
    @State private var generateCardsPrompt = ""
    @State private var generateCardsCount = 10
    @State private var isGeneratingCards = false
    @State private var generateCardsErrorMessage: String?

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
            .navigationTitle(L10n.decks)
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
                        generateCardsPrompt = ""
                        generateCardsErrorMessage = nil
                        showingGenerateCards = true
                    } label: {
                        Image(systemName: "wand.and.stars")
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
            .sheet(isPresented: $showingGenerateCards) {
                generateCardsSheet
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
            Text(L10n.noDecksYet)
                .font(AppTypography.title2)
            Text(L10n.tapPlusToCreateFirst)
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
                TextField(L10n.deckNamePlaceholder, text: $newDeckName)
            }
            .navigationTitle(L10n.newDeck)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        showingAddDeck = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.create) {
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

    private var generateCardsSheet: some View {
        let availability = AICardsGenerationService.checkAvailability()
        return NavigationStack {
            Form {
                Section {
                    TextField(L10n.generateCardsPromptPlaceholder, text: $generateCardsPrompt, axis: .vertical)
                        .lineLimit(2...4)
                } footer: {
                    Text(L10n.generateCardsPromptFooter)
                }

                Section(L10n.cardsQuantity) {
                    Picker(L10n.cardsQuantity, selection: $generateCardsCount) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("15").tag(15)
                        Text("20").tag(20)
                    }
                    .pickerStyle(.segmented)
                }

                if !availability.canGenerate {
                    Section {
                        Text(availabilityMessage(availability))
                            .font(AppTypography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let message = generateCardsErrorMessage {
                    Section {
                        Text(message)
                            .font(AppTypography.subheadline)
                            .foregroundStyle(Color("ErrorColor"))
                    }
                }
            }
            .navigationTitle(L10n.generateCardsWithAI)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        showingGenerateCards = false
                    }
                    .disabled(isGeneratingCards)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isGeneratingCards {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(L10n.generate) {
                            runGenerateCards(availability: availability)
                        }
                        .disabled(generateCardsPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !availability.canGenerate)
                    }
                }
            }
            .interactiveDismissDisabled(isGeneratingCards)
        }
    }

    private func availabilityMessage(_ availability: AICardsGenerationAvailability) -> String {
        switch availability {
        case .available:
            return ""
        case .unavailableDeviceNotEligible:
            return L10n.aiUnavailableDevice
        case .unavailableAppleIntelligenceNotEnabled:
            return L10n.aiUnavailableNotEnabled
        case .unavailableModelNotReady:
            return L10n.aiUnavailableModelNotReady
        case .unavailableOther:
            return L10n.aiUnavailableOther
        }
    }

    private func runGenerateCards(availability: AICardsGenerationAvailability) {
        guard availability.canGenerate else { return }
        let prompt = generateCardsPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        generateCardsErrorMessage = nil
        isGeneratingCards = true
        Task {
            do {
                let pairs = try await AICardsGenerationService.generateCards(userPrompt: prompt, count: generateCardsCount)
                await MainActor.run {
                    addGeneratedDeckWithCards(prompt: prompt, pairs: pairs)
                    isGeneratingCards = false
                    showingGenerateCards = false
                    viewModel.fetchDecks()
                }
            } catch {
                await MainActor.run {
                    generateCardsErrorMessage = errorMessage(for: error)
                    isGeneratingCards = false
                }
            }
        }
    }

    private func addGeneratedDeckWithCards(prompt: String, pairs: [(front: String, back: String, difficulty: CardDifficulty)]) {
        let name = AICardsGenerationService.deckName(fromUserPrompt: prompt)
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.orderIndex)])
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let deck = Deck(name: name, orderIndex: 0)
        modelContext.insert(deck)
        for d in existing {
            d.orderIndex += 1
        }
        DecksJSONService.appendDeck(id: deck.id, name: deck.name, orderIndex: 0)
        for (index, pair) in pairs.enumerated() {
            let card = Card(
                front: pair.front,
                back: pair.back,
                tags: ["IA"],
                difficulty: pair.difficulty,
                orderIndex: index,
                deck: deck
            )
            modelContext.insert(card)
            DecksJSONService.appendCard(deckId: deck.id, front: pair.front, back: pair.back, tags: ["IA"], difficulty: pair.difficulty)
        }
        try? modelContext.save()
        viewModel.fetchDecks()
    }

    private func errorMessage(for error: Error) -> String {
        if let aiError = error as? AICardsGenerationError {
            return aiError.localizedDescription
        }
        let nsError = error as NSError
        if nsError.domain == "FoundationModels.LanguageModelSession.GenerationError" ||
            String(describing: type(of: error)).contains("GenerationError") {
            if nsError.localizedDescription.lowercased().contains("context") {
                return L10n.errorTryFewerCards
            }
        }
        return L10n.errorCouldNotGenerate
    }
}

struct DeckRowView: View {
    let deck: Deck

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(deck.name)
                    .font(AppTypography.title2)
                Text(L10n.cardsCountDominanceFormatted(cards: deck.cards.count, percent: Int(deck.dominancePercentage * 100)))
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
