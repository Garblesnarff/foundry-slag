// Copyright © 2026 Hanson Foundry. All rights reserved.

import AppKit
import CoreImage
import Foundation
import Vision

// MARK: - SlagEngine

/// ObservableObject wrapping Core Image and Vision framework for background removal.
/// Uses `VNGenerateForegroundInstanceMaskRequest` on macOS 14+ for high-quality
/// subject isolation, with a fallback to `VNGeneratePersonSegmentationRequest` on macOS 13.
@MainActor
final class SlagEngine: ObservableObject {
    static let shared = SlagEngine()

    @Published var isProcessing = false
    @Published var progress: Double = 0
    @Published var currentModel: String = "vision-auto"

    private let ciContext = CIContext()

    private init() {}

    // MARK: - Public API

    /// Remove background from an image document. Updates the document's state, mask, and result.
    func slag(document: ImageDocument) async {
        guard !document.isProcessing else { return }

        document.state = .processing
        isProcessing = true
        progress = 0

        let startTime = CFAbsoluteTimeGetCurrent()

        guard let cgImage = document.originalImage.cgImage(
            forProposedRect: nil, context: nil, hints: nil
        ) else {
            document.state = .failed("Could not read image data.")
            isProcessing = false
            return
        }

        progress = 0.1

        do {
            let mask = try await generateMask(for: cgImage)
            progress = 0.7

            let result = compositeResult(source: cgImage, mask: mask)
            progress = 0.9

            document.maskImage = mask
            document.resultImage = result
            document.state = .done

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            let _ = Int(elapsed * 1000) // processing time in ms
        } catch {
            document.state = .failed(error.localizedDescription)
        }

        progress = 1.0
        isProcessing = false
    }

    /// Process a batch of documents sequentially with progress reporting.
    func slagBatch(documents: [ImageDocument]) async {
        isProcessing = true
        let total = documents.count

        for (index, doc) in documents.enumerated() {
            progress = Double(index) / Double(total)
            await slag(document: doc)
        }

        progress = 1.0
        isProcessing = false
    }

    // MARK: - Mask Generation

    private func generateMask(for cgImage: CGImage) async throws -> CIImage {
        // macOS 14+: Use VNGenerateForegroundInstanceMaskRequest for best quality
        if #available(macOS 14.0, *) {
            if let mask = try? await runForegroundInstanceMask(cgImage: cgImage) {
                return mask
            }
        }

        // Fallback: person segmentation (macOS 13+)
        if let personMask = try? await runPersonSegmentation(cgImage: cgImage) {
            return personMask
        }

        // Last resort: saliency-based mask
        return try await runSaliencyMask(cgImage: cgImage)
    }

    // MARK: - Foreground Instance Mask (macOS 14+)

    @available(macOS 14.0, *)
    private func runForegroundInstanceMask(cgImage: CGImage) async throws -> CIImage {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNGenerateForegroundInstanceMaskRequest()

        try handler.perform([request])

        guard let result = request.results?.first else {
            throw SlagEngineError.noResults
        }

        // Generate a mask covering all foreground instances
        let allInstances = result.allInstances
        let maskPixelBuffer = try result.generateMaskedImage(
            ofInstances: allInstances,
            from: handler,
            croppedToInstancesExtent: false
        )

        return CIImage(cvPixelBuffer: maskPixelBuffer)
    }

    // MARK: - Person Segmentation (macOS 13+)

    private func runPersonSegmentation(cgImage: CGImage) async throws -> CIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = request.results?.first as? VNPixelBufferObservation else {
                    continuation.resume(throwing: SlagEngineError.noResults)
                    return
                }
                let maskCI = CIImage(cvPixelBuffer: result.pixelBuffer)
                continuation.resume(returning: maskCI)
            }
            request.qualityLevel = .accurate
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Saliency Fallback

    private func runSaliencyMask(cgImage: CGImage) async throws -> CIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = request.results?.first as? VNSaliencyImageObservation else {
                    continuation.resume(throwing: SlagEngineError.noResults)
                    return
                }
                let salientObjects = result.salientObjects ?? []
                let mask = Self.buildSaliencyMask(
                    from: salientObjects,
                    imageSize: CGSize(width: cgImage.width, height: cgImage.height)
                )
                continuation.resume(returning: mask)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func buildSaliencyMask(
        from objects: [VNRectangleObservation],
        imageSize: CGSize
    ) -> CIImage {
        let w = imageSize.width
        let h = imageSize.height

        var mask = CIImage(color: .black).cropped(to: CGRect(origin: .zero, size: imageSize))

        for obj in objects {
            let rect = CGRect(
                x: obj.boundingBox.minX * w,
                y: obj.boundingBox.minY * h,
                width: obj.boundingBox.width * w,
                height: obj.boundingBox.height * h
            )
            let patch = CIImage(color: .white).cropped(to: rect)
            mask = patch.composited(over: mask)
        }

        if objects.isEmpty {
            let cx = w * 0.5, cy = h * 0.5
            let rx = w * 0.3, ry = h * 0.3
            let rect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
            let patch = CIImage(color: .white).cropped(to: rect)
            mask = patch.composited(over: mask)
        }

        return mask
    }

    // MARK: - Compositing

    private func compositeResult(source cgImage: CGImage, mask: CIImage) -> NSImage? {
        let source = CIImage(cgImage: cgImage)

        // Scale mask to match source if sizes differ
        let scaleX = source.extent.width / mask.extent.width
        let scaleY = source.extent.height / mask.extent.height
        let scaledMask: CIImage
        if abs(scaleX - 1) > 0.001 || abs(scaleY - 1) > 0.001 {
            scaledMask = mask.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        } else {
            scaledMask = mask
        }

        let masked = source.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: scaledMask
        ])

        guard let cgResult = ciContext.createCGImage(masked, from: masked.extent) else {
            return nil
        }

        let size = CGSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgResult, size: size)
    }
}

// MARK: - Errors

enum SlagEngineError: LocalizedError {
    case noResults
    case unsupportedFormat
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No segmentation results were produced."
        case .unsupportedFormat:
            return "The image format is not supported."
        case .processingFailed(let msg):
            return "Processing failed: \(msg)"
        }
    }
}
