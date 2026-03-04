//
//  SettingsView.swift
//  FlashCards
//

internal import SwiftUI
import SwiftData
import UniformTypeIdentifiers

private enum SettingsKeys {
    static let notificationsEnabled = "notificationsEnabled"
    static let ttsEnabled = "ttsEnabled"
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthService()
    @AppStorage(SettingsKeys.notificationsEnabled) private var notificationsEnabled = true
    @AppStorage(SettingsKeys.ttsEnabled) private var ttsEnabled = true
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var exportData: Data?
    @State private var importError: String?
    @State private var importSuccess = false
    @State private var selectedLanguage: AppLanguage?
    @Query(sort: \Deck.orderIndex) private var decks: [Deck]

    init() {
        _selectedLanguage = State(initialValue: AppLanguageManager.storedAppLanguage)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.language) {
                    Picker(L10n.language, selection: $selectedLanguage) {
                        Text(L10n.languageSystem).tag(Optional<AppLanguage>.none)
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(Optional<AppLanguage>.some(lang))
                        }
                    }
                    .onChange(of: selectedLanguage) { _, new in
                        if let lang = new {
                            AppLanguageManager.shared.setLanguage(lang)
                        } else {
                            AppLanguageManager.shared.useSystemLanguage()
                        }
                    }
                }
                Section(L10n.account) {
                    Button(L10n.signOut, role: .destructive) {
                        authService.signOut()
                        dismiss()
                    }
                }
                Section(L10n.studySection) {
                    Toggle(L10n.reviewNotifications, isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            if enabled {
                                Task {
                                    let granted = await NotificationService.requestPermission()
                                    if granted {
                                        NotificationService.scheduleDailyReminder()
                                    } else {
                                        await MainActor.run { notificationsEnabled = false }
                                    }
                                }
                            } else {
                                NotificationService.cancelDailyReminder()
                            }
                        }
                    Toggle(L10n.tts, isOn: $ttsEnabled)
                }
                Section(L10n.data) {
                    Button(L10n.exportDecksJSON) {
                        exportDecks()
                    }
                    .disabled(decks.isEmpty)
                    Button(L10n.importDecksJSON) {
                        showingImportPicker = true
                    }
                }
                if let msg = importError {
                    Section {
                        Text(msg)
                            .foregroundStyle(Color("ErrorColor"))
                    }
                }
                if importSuccess {
                    Section {
                        Text(L10n.importSuccess)
                            .foregroundStyle(Color("SuccessColor"))
                    }
                }
            }
            .navigationTitle(L10n.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.done) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(data: data, fileName: "flashcards-export.json")
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importFrom(url: url)
                case .failure:
                    importError = L10n.importErrorFile
                }
            }
        }
        .onAppear {
            importError = nil
            importSuccess = false
            if notificationsEnabled {
                Task {
                    _ = await NotificationService.requestPermission()
                    NotificationService.scheduleDailyReminder()
                }
            }
        }
    }

    private func exportDecks() {
        exportData = ExportImportService.exportDecks(decks)
        showingExportSheet = true
    }

    private func importFrom(url: URL) {
        importError = nil
        importSuccess = false
        guard url.startAccessingSecurityScopedResource() else {
            importError = L10n.importErrorAccess
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            _ = try ExportImportService.importDecks(from: data, into: modelContext)
            importSuccess = true
        } catch {
            importError = L10n.importErrorGeneric(error.localizedDescription)
        }
    }
}

/// Share sheet for exporting data
struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let fileName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    let schema = Schema([Deck.self, Card.self, StudySession.self])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [config])
    return SettingsView()
        .modelContainer(container)
}
