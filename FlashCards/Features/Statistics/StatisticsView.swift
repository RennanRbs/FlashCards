//
//  StatisticsView.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudySession.startedAt, order: .reverse) private var sessions: [StudySession]
    @Query(sort: \Deck.orderIndex) private var decks: [Deck]

    init() {}

    private var totalCorrect: Int { sessions.reduce(0) { $0 + $1.correctCount } }
    private var totalIncorrect: Int { sessions.reduce(0) { $0 + $1.incorrectCount } }
    private var totalStudied: Int { totalCorrect + totalIncorrect }
    private var successRate: Double {
        guard totalStudied > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalStudied)
    }
    private var streakDays: Int {
        var streak = 0
        var calendar = Calendar.current
        calendar.startOfDay(for: Date())
        var check = calendar.startOfDay(for: Date())
        let sessionDates = Set(sessions.compactMap { $0.endedAt }.map { calendar.startOfDay(for: $0) })
        while sessionDates.contains(check) {
            streak += 1
            check = calendar.date(byAdding: .day, value: -1, to: check) ?? check
        }
        return streak
    }

    /// Last 7 days for chart: date -> (correct, incorrect)
    private var weeklyData: [DayStat] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [DayStat] = []
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let daySessions = sessions.filter { session in
                guard let end = session.endedAt else { return false }
                return calendar.isDate(end, inSameDayAs: date)
            }
            let c = daySessions.reduce(0) { $0 + $1.correctCount }
            let i = daySessions.reduce(0) { $0 + $1.incorrectCount }
            result.append(DayStat(date: date, correct: c, incorrect: i))
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.xl) {
                        overviewSection
                        chartSection
                        performanceByDeckSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Estatísticas")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Visão geral")
                .font(AppTypography.headline)
            HStack(spacing: AppSpacing.lg) {
                statBlock(title: "Acertos", value: "\(Int(successRate * 100))%", color: Color("SuccessColor"))
                statBlock(title: "Streak", value: "\(streakDays) dias", color: Color("PrimaryColor"))
                statBlock(title: "Estudados", value: "\(totalStudied)", color: Color("PrimaryColor"))
            }
        }
    }

    private func statBlock(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(AppTypography.title2)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .background(Color("CardBackgroundColor"), in: RoundedRectangle(cornerRadius: AppSpacing.sm))
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Evolução semanal")
                .font(AppTypography.headline)
            Chart(weeklyData) { item in
                LineMark(
                    x: .value("Dia", item.date),
                    y: .value("Acertos", item.correct)
                )
                .foregroundStyle(Color("SuccessColor"))
                BarMark(
                    x: .value("Dia", item.date),
                    y: .value("Erros", item.incorrect)
                )
                .foregroundStyle(Color("ErrorColor").opacity(0.7))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 180)
        }
    }

    private var performanceByDeckSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Por deck")
                .font(AppTypography.headline)
            ForEach(decks, id: \.id) { deck in
                HStack {
                    Text(deck.name)
                        .font(AppTypography.bodyMedium)
                    Spacer()
                    Text("\(Int(deck.dominancePercentage * 100))%")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                    ProgressBar(progress: deck.dominancePercentage)
                        .frame(width: 80)
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }
}

#Preview {
    let schema = Schema([Deck.self, Card.self, StudySession.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return StatisticsView()
        .modelContainer(container)
}

private struct DayStat: Identifiable {
    let id: Date
    let date: Date
    let correct: Int
    let incorrect: Int
    init(date: Date, correct: Int, incorrect: Int) {
        self.id = date
        self.date = date
        self.correct = correct
        self.incorrect = incorrect
    }
}
