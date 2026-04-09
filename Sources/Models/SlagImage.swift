// Copyright © 2026 Hanson Foundry. All rights reserved.

import AppKit
import Foundation

// MARK: - SlagImage

/// A lightweight model representing a processed image entry for history and batch tracking.
/// Unlike `ImageDocument` (the live working document), `SlagImage` is a persistent record
/// of a completed slagging operation.
struct SlagImage: Identifiable, Codable {
    let id: UUID
    let originalFileName: String
    let processingDate: Date
    var processingTimeMs: Int
    var modelUsed: String
    var featherRadius: Double
    var edgeShift: Double
    var exportFormatRaw: String
    var status: SlagStatus

    // File paths for persistence (relative to app support directory)
    var originalPath: String?
    var resultPath: String?
    var thumbnailPath: String?

    init(
        id: UUID = UUID(),
        originalFileName: String,
        processingDate: Date = Date(),
        processingTimeMs: Int = 0,
        modelUsed: String = "vision",
        featherRadius: Double = 2.0,
        edgeShift: Double = 0.0,
        exportFormatRaw: String = "PNG",
        status: SlagStatus = .queued
    ) {
        self.id = id
        self.originalFileName = originalFileName
        self.processingDate = processingDate
        self.processingTimeMs = processingTimeMs
        self.modelUsed = modelUsed
        self.featherRadius = featherRadius
        self.edgeShift = edgeShift
        self.exportFormatRaw = exportFormatRaw
        self.status = status
    }

    var displayName: String {
        (originalFileName as NSString).deletingPathExtension
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: processingDate)
    }

    var formattedProcessingTime: String {
        if processingTimeMs < 1000 {
            return "\(processingTimeMs)ms"
        }
        let seconds = Double(processingTimeMs) / 1000.0
        return String(format: "%.1fs", seconds)
    }
}

// MARK: - SlagStatus

enum SlagStatus: String, Codable {
    case queued
    case slagging
    case slagged
    case failed

    var displayLabel: String {
        switch self {
        case .queued: return "Queued"
        case .slagging: return "Slagging..."
        case .slagged: return "Slagged!"
        case .failed: return "Failed"
        }
    }
}
