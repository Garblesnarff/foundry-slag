// Copyright © 2026 Hanson Foundry. All rights reserved.

import AppKit
import Foundation

// MARK: - ImageStore

/// ObservableObject that manages the collection of images being processed.
/// Handles batch operations, selection state, and coordinates with SlagEngine.
@MainActor
final class ImageStore: ObservableObject {
    @Published var documents: [ImageDocument] = []
    @Published var selectedDocument: ImageDocument?
    @Published var isBatchProcessing = false
    @Published var batchProgress: Double = 0
    @Published var batchTotal: Int = 0
    @Published var batchCompleted: Int = 0

    private let engine = SlagEngine.shared

    // MARK: - Single Image

    func addImage(from url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        let doc = ImageDocument(url: url, image: image)
        documents.insert(doc, at: 0)
        selectedDocument = doc

        Task {
            await engine.slag(document: doc)
        }
    }

    func addImage(data: Data, name: String) {
        guard let image = NSImage(data: data) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        let doc = ImageDocument(url: url, image: image)
        documents.insert(doc, at: 0)
        selectedDocument = doc

        Task {
            await engine.slag(document: doc)
        }
    }

    // MARK: - Batch

    func addBatch(urls: [URL]) {
        let newDocs: [ImageDocument] = urls.compactMap { url in
            guard let image = NSImage(contentsOf: url) else { return nil }
            return ImageDocument(url: url, image: image)
        }

        documents.insert(contentsOf: newDocs, at: 0)
        if selectedDocument == nil {
            selectedDocument = newDocs.first
        }

        Task {
            await processBatch(newDocs)
        }
    }

    private func processBatch(_ docs: [ImageDocument]) async {
        isBatchProcessing = true
        batchTotal = docs.count
        batchCompleted = 0
        batchProgress = 0

        for doc in docs {
            await engine.slag(document: doc)
            batchCompleted += 1
            batchProgress = Double(batchCompleted) / Double(batchTotal)
        }

        isBatchProcessing = false
    }

    // MARK: - Selection

    func select(_ document: ImageDocument) {
        selectedDocument = document
    }

    // MARK: - Removal

    func removeDocument(_ document: ImageDocument) {
        documents.removeAll { $0.id == document.id }
        if selectedDocument?.id == document.id {
            selectedDocument = documents.first
        }
    }

    func removeAll() {
        documents.removeAll()
        selectedDocument = nil
    }

    // MARK: - Re-process

    func reslagDocument(_ document: ImageDocument) {
        Task {
            await engine.slag(document: document)
        }
    }

    func reslagAll() {
        let docs = documents
        Task {
            await processBatch(docs)
        }
    }

    // MARK: - Queries

    var completedCount: Int {
        documents.filter(\.isDone).count
    }

    var failedCount: Int {
        documents.filter { if case .failed = $0.state { return true }; return false }.count
    }

    var processingCount: Int {
        documents.filter(\.isProcessing).count
    }
}
