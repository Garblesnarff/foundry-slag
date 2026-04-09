// Copyright © 2026 Hanson Foundry. All rights reserved.

import Foundation

// MARK: - HistoryStore

/// ObservableObject that manages the processing history, persisted to disk as JSON.
@MainActor
final class HistoryStore: ObservableObject {
    @Published var entries: [SlagImage] = []

    private let storageURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let slagDir = appSupport.appendingPathComponent("FoundrySlag", isDirectory: true)

        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: slagDir, withIntermediateDirectories: true
        )

        self.storageURL = slagDir.appendingPathComponent("history.json")
        loadHistory()
    }

    // MARK: - Add Entry

    func addEntry(from document: ImageDocument, processingTimeMs: Int = 0) {
        let entry = SlagImage(
            originalFileName: document.sourceURL.lastPathComponent,
            processingDate: Date(),
            processingTimeMs: processingTimeMs,
            modelUsed: "vision-auto",
            featherRadius: document.featherRadius,
            edgeShift: document.edgeShift,
            exportFormatRaw: "PNG",
            status: document.isDone ? .slagged : .failed
        )
        entries.insert(entry, at: 0)
        saveHistory()
    }

    func addEntry(_ entry: SlagImage) {
        entries.insert(entry, at: 0)
        saveHistory()
    }

    // MARK: - Remove

    func removeEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        saveHistory()
    }

    func clearHistory() {
        entries.removeAll()
        saveHistory()
    }

    // MARK: - Persistence

    func loadHistory() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }

        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([SlagImage].self, from: data)
        } catch {
            // Silently handle corrupt history
            entries = []
        }
    }

    func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            // Silently handle write failure
        }
    }

    // MARK: - Queries

    var slaggedCount: Int {
        entries.filter { $0.status == .slagged }.count
    }

    var failedCount: Int {
        entries.filter { $0.status == .failed }.count
    }

    func entries(for dateRange: ClosedRange<Date>) -> [SlagImage] {
        entries.filter { dateRange.contains($0.processingDate) }
    }
}
