//
//  FlashCardsApp.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData

@main
struct FlashCardsApp: App {
    var sharedModelContainer: ModelContainer = {
        let modelTypes: [any PersistentModel.Type] = [Deck.self, Card.self, StudySession.self]
        let schema = Schema(modelTypes)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    HapticsManager.prepare()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
