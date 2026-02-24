//
//  SmartFlashcardsWidget.swift
//  SmartFlashcardsWidget
//
//  Widget Extension target. Enable App Group "group.rennanRBS.FlashCards" for this target.
//

import WidgetKit
import SwiftUI

struct FlashCardsWidgetEntry: TimelineEntry {
    let date: Date
    let lastDeckName: String?
    let cardsStudiedThisWeek: Int
    let streakDays: Int
}

struct FlashCardsWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlashCardsWidgetEntry {
        FlashCardsWidgetEntry(date: Date(), lastDeckName: "SwiftUI", cardsStudiedThisWeek: 24, streakDays: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlashCardsWidgetEntry) -> Void) {
        let defaults = UserDefaults(suiteName: "group.rennanRBS.FlashCards")
        let entry = FlashCardsWidgetEntry(
            date: Date(),
            lastDeckName: defaults?.string(forKey: "lastDeckName"),
            cardsStudiedThisWeek: defaults?.integer(forKey: "cardsStudiedThisWeek") ?? 0,
            streakDays: defaults?.integer(forKey: "streakDays") ?? 0
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlashCardsWidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.rennanRBS.FlashCards")
        let entry = FlashCardsWidgetEntry(
            date: Date(),
            lastDeckName: defaults?.string(forKey: "lastDeckName"),
            cardsStudiedThisWeek: defaults?.integer(forKey: "cardsStudiedThisWeek") ?? 0,
            streakDays: defaults?.integer(forKey: "streakDays") ?? 0
        )
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 12, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct FlashCardsWidgetEntryView: View {
    var entry: FlashCardsWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Continue estudando")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let name = entry.lastDeckName, !name.isEmpty {
                Text(name)
                    .font(.headline)
            }
            HStack {
                Label("\(entry.cardsStudiedThisWeek) esta semana", systemImage: "chart.bar")
                    .font(.caption2)
                Text("•")
                Label("\(entry.streakDays) dias", systemImage: "flame")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }
}

struct SmartFlashcardsWidget: Widget {
    let kind: String = "SmartFlashcardsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlashCardsWidgetProvider()) { entry in
            FlashCardsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Smart Flashcards")
        .description("Continue estudando. Último deck e progresso da semana.")
    }
}

#Preview(as: .systemSmall) {
    SmartFlashcardsWidget()
} timeline: {
    FlashCardsWidgetEntry(date: Date(), lastDeckName: "SwiftUI", cardsStudiedThisWeek: 24, streakDays: 3)
}
