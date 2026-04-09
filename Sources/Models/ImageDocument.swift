// Copyright © 2026 Hanson Foundry. All rights reserved.

import AppKit
import CoreImage
import Foundation

// MARK: - Processing State

enum ProcessingState: Equatable {
    case idle
    case processing
    case done
    case failed(String)
}

// MARK: - Background Mode

enum BackgroundMode: Equatable {
    case transparent
    case color(NSColor)
    case image(URL)
}

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case png = "PNG"
    case jpg = "JPG"

    var id: String { rawValue }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpg: return "jpg"
        }
    }
}

// MARK: - ImageDocument

final class ImageDocument: ObservableObject, Identifiable {
    let id: UUID
    let sourceURL: URL
    let originalImage: NSImage

    @Published var state: ProcessingState = .idle
    @Published var maskImage: CIImage?
    @Published var resultImage: NSImage?

    // Edge refinement parameters
    @Published var featherRadius: Double = 2.0
    @Published var edgeShift: Double = 0.0

    // Background
    @Published var backgroundMode: BackgroundMode = .transparent

    // Timestamps
    let createdAt: Date

    init(url: URL, image: NSImage) {
        self.id = UUID()
        self.sourceURL = url
        self.originalImage = image
        self.createdAt = Date()
    }

    var displayName: String {
        sourceURL.deletingPathExtension().lastPathComponent
    }

    var thumbnailImage: NSImage? {
        guard let result = resultImage else { return originalImage }
        return result
    }

    var isProcessing: Bool {
        state == .processing
    }

    var isDone: Bool {
        if case .done = state { return true }
        return false
    }

    // Composite the result image with current background settings
    func compositeWithBackground() -> NSImage? {
        guard let maskImage = maskImage,
              let cgSource = originalImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return resultImage }

        let sourceCI = CIImage(cgImage: cgSource)
        let context = CIContext()

        // Apply edge refinement to mask
        let refinedMask = applyEdgeRefinement(to: maskImage)

        // Apply mask to source
        let masked = sourceCI.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: refinedMask
        ])

        switch backgroundMode {
        case .transparent:
            guard let cgResult = context.createCGImage(masked, from: masked.extent) else { return nil }
            return NSImage(cgImage: cgResult, size: originalImage.size)

        case .color(let color):
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.usingColorSpace(.sRGB)?.getRed(&r, green: &g, blue: &b, alpha: &a)
            let bgCI = CIImage(color: CIColor(red: r, green: g, blue: b, alpha: 1.0))
                .cropped(to: masked.extent)
            let composited = masked.composited(over: bgCI)
            guard let cgResult = context.createCGImage(composited, from: composited.extent) else { return nil }
            return NSImage(cgImage: cgResult, size: originalImage.size)

        case .image(let bgURL):
            guard let bgNSImage = NSImage(contentsOf: bgURL),
                  let bgCG = bgNSImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
            else {
                guard let cgResult = context.createCGImage(masked, from: masked.extent) else { return nil }
                return NSImage(cgImage: cgResult, size: originalImage.size)
            }
            let bgCI = CIImage(cgImage: bgCG)
                .transformed(by: CGAffineTransform(
                    scaleX: masked.extent.width / CIImage(cgImage: bgCG).extent.width,
                    y: masked.extent.height / CIImage(cgImage: bgCG).extent.height
                ))
                .cropped(to: masked.extent)
            let composited = masked.composited(over: bgCI)
            guard let cgResult = context.createCGImage(composited, from: composited.extent) else { return nil }
            return NSImage(cgImage: cgResult, size: originalImage.size)
        }
    }

    private func applyEdgeRefinement(to mask: CIImage) -> CIImage {
        var result = mask

        // Edge shift: positive = expand (dilate), negative = contract (erode)
        if edgeShift != 0 {
            let morphRadius = abs(edgeShift)
            let filterName = edgeShift > 0 ? "CIMorphologyMaximum" : "CIMorphologyMinimum"
            result = result.applyingFilter(filterName, parameters: [
                kCIInputRadiusKey: morphRadius
            ])
        }

        // Feather: gaussian blur on alpha edges
        if featherRadius > 0 {
            result = result.applyingFilter("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: featherRadius
            ])
            // Clamp to original extent after blur
            result = result.cropped(to: mask.extent)
        }

        return result
    }
}


