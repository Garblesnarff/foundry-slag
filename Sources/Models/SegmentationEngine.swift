// Copyright © 2026 Hanson Foundry. All rights reserved.

import AppKit
import CoreImage
import Foundation
import Vision

// MARK: - Segmentation Engine

actor SegmentationEngine {
    static let shared = SegmentationEngine()

    private init() {}

    // MARK: - Public API

    /// Process a document: runs segmentation and composites the result back onto the document.
    func process(document: ImageDocument) async {
        await MainActor.run { document.state = .processing }

        guard let cgImage = await MainActor.run(body: {
            document.originalImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }) else {
            await MainActor.run { document.state = .failed("Could not read image data.") }
            return
        }

        do {
            let mask = try await generateMask(for: cgImage)
            let result = composite(cgImage: cgImage, mask: mask)
            await MainActor.run {
                document.maskImage = mask
                document.resultImage = result
                document.state = .done
            }
        } catch {
            await MainActor.run {
                document.state = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Mask Generation

    private func generateMask(for cgImage: CGImage) async throws -> CIImage {
        // Try person segmentation first
        if let personMask = try? await runPersonSegmentation(cgImage: cgImage) {
            return personMask
        }
        // Fallback: attention-based saliency
        return try await runSaliencyMask(cgImage: cgImage)
    }

    // MARK: - Person Segmentation (VNGeneratePersonSegmentationRequest)

    private func runPersonSegmentation(cgImage: CGImage) async throws -> CIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGeneratePersonSegmentationRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = request.results?.first as? VNPixelBufferObservation else {
                    continuation.resume(throwing: SegmentationError.noResults)
                    return
                }
                let maskCI = CIImage(cvPixelBuffer: result.pixelBuffer)
                    .oriented(.downMirrored)
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

    // MARK: - Saliency Fallback (VNGenerateAttentionBasedSaliencyImageRequest)

    private func runSaliencyMask(cgImage: CGImage) async throws -> CIImage {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result = request.results?.first as? VNSaliencyImageObservation else {
                    continuation.resume(throwing: SegmentationError.noResults)
                    return
                }
                // Build a mask from salient objects bounding boxes
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

    // MARK: - Helpers

    private static func buildSaliencyMask(
        from objects: [VNRectangleObservation],
        imageSize: CGSize
    ) -> CIImage {
        // Render white rectangles for each salient region onto a black background.
        // Vision normalised coords: origin bottom-left, 0-1 range.
        let w = imageSize.width
        let h = imageSize.height

        let renderer = CIContext()
        _ = renderer // suppress warning

        // Build using CoreImage solid colour + compositing
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
            // No salient objects detected — use a centred oval covering 60% of the frame
            let cx = w * 0.5
            let cy = h * 0.5
            let rx = w * 0.3
            let ry = h * 0.3
            let rect = CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2)
            let patch = CIImage(color: .white).cropped(to: rect)
            mask = patch.composited(over: mask)
        }

        return mask
    }

    // MARK: - Compositing

    private func composite(cgImage: CGImage, mask: CIImage) -> NSImage? {
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

        let context = CIContext()
        guard let cgResult = context.createCGImage(masked, from: masked.extent) else { return nil }

        let size = CGSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgResult, size: size)
    }
}

// MARK: - Errors

enum SegmentationError: LocalizedError {
    case noResults
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .noResults: return "No segmentation results were produced."
        case .unsupportedFormat: return "The image format is not supported."
        }
    }
}
