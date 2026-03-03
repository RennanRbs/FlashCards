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

    private var generateCardsSheet: some View {
        let availability = AICardsGenerationService.checkAvailability()
        return NavigationStack {
            Form {
                Section {
                    TextField("Ex.: pokemon, direito civil brasileiro, dinossauros", text: $generateCardsPrompt, axis: .vertical)
                        .lineLimit(2...4)
                } footer: {
                    Text("Digite o tema para criar cards. A IA criará um deck com perguntas e respostas sobre o assunto.")
                }

                Section("Quantidade de cards") {
                    Picker("Quantidade", selection: $generateCardsCount) {
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
            .navigationTitle("Gerar cards com IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        showingGenerateCards = false
                    }
                    .disabled(isGeneratingCards)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isGeneratingCards {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Gerar") {
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
            return "Apple Intelligence não está disponível neste dispositivo."
        case .unavailableAppleIntelligenceNotEnabled:
            return "Ative o Apple Intelligence em Ajustes para gerar cards."
        case .unavailableModelNotReady:
            return "O modelo ainda está sendo preparado. Tente novamente em instantes."
        case .unavailableOther:
            return "Apple Intelligence não está disponível no momento."
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

    private func addGeneratedDeckWithCards(prompt: String, pairs: [(front: String, back: String)]) {
        let name = AICardsGenerationService.deckName(fromUserPrompt: prompt)
        let maxIndex = (try? modelContext.fetch(FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.orderIndex)])))?.last?.orderIndex ?? -1
        let deck = Deck(name: name, orderIndex: maxIndex + 1)
        modelContext.insert(deck)
        DecksJSONService.appendDeck(id: deck.id, name: deck.name, orderIndex: deck.orderIndex)
        for (index, pair) in pairs.enumerated() {
            let card = Card(
                front: pair.front,
                back: pair.back,
                tags: ["IA"],
                orderIndex: index,
                deck: deck
            )
            modelContext.insert(card)
            DecksJSONService.appendCard(deckId: deck.id, front: pair.front, back: pair.back, tags: ["IA"])
        }
        try? modelContext.save()
        viewModel.fetchDecks()
    }

    private func errorMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == "FoundationModels.LanguageModelSession.GenerationError" ||
            String(describing: type(of: error)).contains("GenerationError") {
            if nsError.localizedDescription.lowercased().contains("context") {
                return "Tente um número menor de cards ou um prompt mais curto."
            }
        }
        return "Não foi possível gerar os cards. Tente novamente."
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
