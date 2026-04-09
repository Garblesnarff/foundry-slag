// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI

@main
struct FoundrySlagApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Image...") {
                    appState.triggerOpenPanel()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open Batch...") {
                    appState.triggerBatchPanel()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            CommandGroup(after: .saveItem) {
                Button("Export...") {
                    appState.triggerExport()
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(appState.selectedDocument == nil)
            }
        }
    }
}

// MARK: - App-wide state

final class AppState: ObservableObject {
    @Published var selectedDocument: ImageDocument?
    @Published var documents: [ImageDocument] = []
    @Published var isBatchMode: Bool = false
    @Published var openPanelTrigger: Bool = false
    @Published var batchPanelTrigger: Bool = false
    @Published var exportTrigger: Bool = false

    func triggerOpenPanel() {
        openPanelTrigger.toggle()
    }

    func triggerBatchPanel() {
        isBatchMode = true
        batchPanelTrigger.toggle()
    }

    func triggerExport() {
        exportTrigger.toggle()
    }

    func addDocument(_ doc: ImageDocument) {
        documents.insert(doc, at: 0)
        selectedDocument = doc
    }

    func removeDocument(_ doc: ImageDocument) {
        documents.removeAll { $0.id == doc.id }
        if selectedDocument?.id == doc.id {
            selectedDocument = documents.first
        }
    }
}
