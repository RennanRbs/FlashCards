//
//  ContentView.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        DecksListView(modelContext: modelContext)
    }
}

#Preview {
    let schema = Schema([Deck.self, Card.self, StudySession.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return ContentView()
        .modelContainer(container)
}
