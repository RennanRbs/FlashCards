//
//  StudyView.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData

private enum StudySettingsKeys {
    static let ttsEnabled = "ttsEnabled" // same as SettingsKeys.ttsEnabled
}

struct StudyView: View {
    let deck: Deck
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var queue: [Card] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var offset: CGFloat = 0
    @State private var session: StudySession?
    @State private var correctCount = 0
    @State private var incorrectCount = 0
    @State private var showingSummary = false
    @State private var dragOffset: CGFloat = 0
    @AppStorage(StudySettingsKeys.ttsEnabled) private var ttsEnabled = true

    private let ttsService = TTSService()
    private var srsService: SRSService { SRSService(modelContext: modelContext) }
    private var currentCard: Card? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            if showingSummary {
                studySummary
            } else if let card = currentCard {
                VStack(spacing: AppSpacing.lg) {
                    progressIndicator
                    Spacer()
                    studyCardView(card)
                    if ttsEnabled {
                        Button {
                            ttsService.stop()
                            ttsService.speak(isFlipped ? card.back : card.front)
                        } label: {
                            Label(L10n.listen, systemImage: "speaker.wave.2")
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                    if isFlipped {
                        responseButtons(card)
                    }
                }
                .padding()
            } else {
                emptyOrLoading
            }
        }
        .onAppear {
            startSession()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.close) {
                    endSession()
                    dismiss()
                }
            }
        }
    }

    private var progressIndicator: some View {
        HStack {
            Text("\(currentIndex + 1) / \(queue.count)")
                .font(AppTypography.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func studyCardView(_ card: Card) -> some View {
        let cardId = card.id
        return ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color("CardBackgroundColor"))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .frame(maxWidth: .infinity)
                .aspectRatio(0.85, contentMode: .fit)
                .padding(.horizontal, AppSpacing.lg)
                .overlay(
                    Group {
                        if isFlipped {
                            Text(card.back)
                                .font(AppTypography.title3)
                                .multilineTextAlignment(.center)
                                .padding(AppSpacing.xl)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        } else {
                            Text(card.front)
                                .font(AppTypography.title3)
                                .multilineTextAlignment(.center)
                                .padding(AppSpacing.xl)
                        }
                    }
                )
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .offset(x: offset + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            dragOffset = 0
                        }
                )
                .onTapGesture {
                    guard !isFlipped else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        HapticsManager.light()
                        isFlipped = true
                    }
                }
        }
        .id(cardId)
    }

    private func responseButtons(_ card: Card) -> some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                submit(.incorrect, for: card)
            } label: {
                VStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "xmark")
                        .font(.title2)
                    Text(L10n.wrong)
                        .font(AppTypography.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color("ErrorColor").opacity(0.2), in: RoundedRectangle(cornerRadius: AppSpacing.sm))
                .foregroundStyle(Color("ErrorColor"))
            }
            .buttonStyle(.plain)

            Button {
                submit(.hard, for: card)
            } label: {
                VStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "questionmark")
                        .font(.title2)
                    Text(L10n.hard)
                        .font(AppTypography.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: AppSpacing.sm))
                .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)

            Button {
                submit(.correct, for: card)
            } label: {
                VStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "checkmark")
                        .font(.title2)
                    Text(L10n.correct)
                        .font(AppTypography.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color("SuccessColor").opacity(0.2), in: RoundedRectangle(cornerRadius: AppSpacing.sm))
                .foregroundStyle(Color("SuccessColor"))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private func submit(_ result: StudyResult, for card: Card) {
        switch result {
        case .incorrect: HapticsManager.error(); incorrectCount += 1
        case .hard: HapticsManager.medium(); correctCount += 1
        case .correct: HapticsManager.success(); correctCount += 1
        }
        srsService.recordResult(result, for: card)
        session?.correctCount = correctCount
        session?.incorrectCount = incorrectCount
        session?.cardsSeen = currentIndex + 1
        try? modelContext.save()

        withAnimation(.easeOut(duration: 0.25)) {
            offset = result == .correct ? 500 : -500
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            nextCard()
        }
    }

    private func nextCard() {
        offset = 0
        isFlipped = false
        currentIndex += 1
        if currentIndex >= queue.count {
            endSession()
            showingSummary = true
        }
    }

    private var emptyOrLoading: some View {
        VStack {
            if queue.isEmpty {
                Text(L10n.noCardsToReview)
                    .font(AppTypography.body)
                    .foregroundStyle(.secondary)
                Button(L10n.close) {
                    dismiss()
                }
                .padding()
            } else {
                ProgressView()
            }
        }
    }

    private var studySummary: some View {
        let successRate = (correctCount + incorrectCount) > 0
            ? Double(correctCount) / Double(correctCount + incorrectCount)
            : 0.0
        let showConfetti = successRate >= 0.8 && (correctCount + incorrectCount) >= 3
        return VStack(spacing: AppSpacing.xl) {
            if showConfetti {
                ConfettiView()
                    .frame(height: 80)
            }
            Text(L10n.sessionComplete)
                .font(AppTypography.title)
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("SuccessColor"))
                    Text(L10n.correctCountFormatted(correctCount))
                }
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color("ErrorColor"))
                    Text(L10n.incorrectCountFormatted(incorrectCount))
                }
            }
            .font(AppTypography.title3)
            PrimaryButton(L10n.close, style: .primary) {
                moveCurrentDeckToEnd()
                dismiss()
            }
            .padding(.horizontal, AppSpacing.xxl)
        }
    }

    private func startSession() {
        queue = SRSService.queueForStudy(from: Array(deck.cards), limit: 50)
        if queue.isEmpty {
            return
        }
        let newSession = StudySession(
            deckId: deck.id,
            startedAt: Date(),
            correctCount: 0,
            incorrectCount: 0,
            cardsSeen: 0
        )
        modelContext.insert(newSession)
        try? modelContext.save()
        session = newSession
    }

    private func endSession() {
        session?.endedAt = Date()
        try? modelContext.save()
        updateWidgetData()
    }

    private func moveCurrentDeckToEnd() {
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.orderIndex)])
        guard var all = try? modelContext.fetch(descriptor),
              let idx = all.firstIndex(where: { $0.id == deck.id }) else { return }
        let d = all.remove(at: idx)
        all.append(d)
        for (i, deck) in all.enumerated() {
            deck.orderIndex = i
        }
        try? modelContext.save()
    }

    private func updateWidgetData() {
        let descriptor = FetchDescriptor<StudySession>(sortBy: [SortDescriptor(\.endedAt, order: .reverse)])
        guard let allSessions = try? modelContext.fetch(descriptor) else { return }
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let cardsThisWeek = allSessions
            .filter { $0.endedAt != nil && ($0.endedAt! >= weekStart) }
            .reduce(0) { $0 + $1.correctCount + $1.incorrectCount }
        var streak = 0
        var check = calendar.startOfDay(for: now)
        let sessionDates = Set(allSessions.compactMap { $0.endedAt }.map { calendar.startOfDay(for: $0) })
        while sessionDates.contains(check) {
            streak += 1
            check = calendar.date(byAdding: .day, value: -1, to: check) ?? check
        }
        WidgetDataStore.write(lastDeckName: deck.name, cardsStudiedThisWeek: cardsThisWeek, streakDays: streak)
    }
}
