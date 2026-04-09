// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI

// MARK: - ResultPreviewView

/// Shows the processed (slagged) image on a checkerboard background
/// to visualise transparency, with zoom and pan controls.
struct ResultPreviewView: View {
    @ObservedObject var document: ImageDocument
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showOriginal = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            ResultToolbar(
                zoomScale: $zoomScale,
                showOriginal: $showOriginal,
                document: document
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.forgePanel)

            Divider().background(Color.forgeBorder)

            // Canvas
            GeometryReader { geo in
                ZStack {
                    // Checkerboard for transparency
                    ResultCheckerboard()

                    // Image
                    if let image = displayImage {
                        let imageView = Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(zoomScale)
                            .offset(offset)
                            .gesture(dragGesture)

                        if #available(macOS 14.0, *) {
                            imageView
                                .gesture(magnificationGesture)
                        } else {
                            imageView
                        }
                    } else if document.isProcessing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(.circular)
                                .tint(.forgeAmber)
                            Text("Slagging...")
                                .font(.system(.callout, design: .monospaced))
                                .foregroundColor(.forgeAmber)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.forgeSubtext)
                            Text("No result yet")
                                .font(.caption)
                                .foregroundColor(.forgeSubtext)
                        }
                    }

                    // State badge
                    VStack {
                        HStack {
                            Spacer()
                            stateBadge
                                .padding(12)
                        }
                        Spacer()
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
            .background(Color.forgeCanvas)
        }
    }

    // MARK: - Display Image

    private var displayImage: NSImage? {
        if showOriginal {
            return document.originalImage
        }
        return document.compositeWithBackground() ?? document.resultImage
    }

    // MARK: - State Badge

    @ViewBuilder
    private var stateBadge: some View {
        switch document.state {
        case .idle:
            EmptyView()
        case .processing:
            BadgePill(text: "Slagging...", color: .forgeAmber)
        case .done:
            BadgePill(text: "Slagged!", color: .forgeGold)
        case .failed(let msg):
            BadgePill(text: "Failed: \(msg)", color: .forgeError)
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { _ in
                // Keep offset
            }
    }

    @available(macOS 14.0, *)
    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoomScale = max(0.25, min(5.0, value.magnification))
            }
    }
}

// MARK: - ResultToolbar

private struct ResultToolbar: View {
    @Binding var zoomScale: CGFloat
    @Binding var showOriginal: Bool
    @ObservedObject var document: ImageDocument

    var body: some View {
        HStack(spacing: 12) {
            Text("Result Preview")
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundColor(.forgeSubtext)

            Spacer()

            // Toggle original
            Toggle(isOn: $showOriginal) {
                Text("Original")
                    .font(.system(.caption2, design: .default))
            }
            .toggleStyle(.switch)
            .controlSize(.mini)
            .tint(.forgeAmber)

            Divider().frame(height: 16)

            // Zoom controls
            HStack(spacing: 6) {
                Button {
                    zoomScale = max(0.25, zoomScale - 0.25)
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .buttonStyle(.plain)
                .foregroundColor(.forgeSubtext)

                Text("\(Int(zoomScale * 100))%")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.forgeAmber)
                    .frame(minWidth: 36)

                Button {
                    zoomScale = min(5.0, zoomScale + 0.25)
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .buttonStyle(.plain)
                .foregroundColor(.forgeSubtext)

                Button {
                    zoomScale = 1.0
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.forgeSubtext)
                .help("Reset zoom")
            }
        }
    }
}

// MARK: - BadgePill

private struct BadgePill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced).weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.forgeBg.opacity(0.85))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.4), lineWidth: 0.5))
    }
}

// MARK: - ResultCheckerboard

private struct ResultCheckerboard: View {
    private let cellSize: CGFloat = 14

    var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width / cellSize))
            let rows = Int(ceil(size.height / cellSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let color = isLight
                        ? Color(white: 0.16)
                        : Color(white: 0.10)
                    let rect = CGRect(
                        x: CGFloat(col) * cellSize,
                        y: CGFloat(row) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
