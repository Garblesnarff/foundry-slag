// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI

// MARK: - CompareSliderView

/// Renders original image on the left, processed result on the right,
/// split by a draggable vertical divider.
struct CompareSliderView: View {
    @ObservedObject var document: ImageDocument
    @State private var sliderPosition: CGFloat = 0.5
    @State private var isDragging = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Checkerboard background for transparency visibility
                CheckerboardView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // "Before" layer: original image, full width, clipped
                if let original = imageToDisplay(.original) {
                    Image(nsImage: original)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // "After" layer: result, clipped to right portion
                if let result = imageToDisplay(.result) {
                    Image(nsImage: result)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(
                            Rectangle().offset(x: geo.size.width * sliderPosition)
                        )
                }

                // Divider line
                Rectangle()
                    .fill(Color.forgeAmber)
                    .frame(width: 2)
                    .offset(x: geo.size.width * sliderPosition - 1)

                // Drag handle
                DragHandle(isDragging: isDragging)
                    .offset(x: geo.size.width * sliderPosition - 18,
                            y: geo.size.height / 2 - 18)

                // Labels
                HStack {
                    Text("Before")
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .foregroundColor(.forgeText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.forgeBg.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(12)
                        .opacity(sliderPosition > 0.15 ? 1 : 0)

                    Spacer()

                    Text("After")
                        .font(.system(.caption2, design: .monospaced).weight(.semibold))
                        .foregroundColor(.forgeGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.forgeBg.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(12)
                        .opacity(sliderPosition < 0.85 ? 1 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                // Invisible drag area
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isDragging = true
                                let newPos = value.location.x / geo.size.width
                                sliderPosition = max(0.02, min(0.98, newPos))
                            }
                            .onEnded { _ in isDragging = false }
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(20)
        }
    }

    // MARK: - Processing state overlay

    private enum ImageSide { case original, result }

    private func imageToDisplay(_ side: ImageSide) -> NSImage? {
        switch side {
        case .original:
            return document.originalImage
        case .result:
            if document.isDone {
                return document.compositeWithBackground() ?? document.resultImage
            }
            return nil
        }
    }
}

// MARK: - DragHandle

private struct DragHandle: View {
    let isDragging: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.forgeAmber)
                .frame(width: 36, height: 36)
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)

            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.forgeBg)
        }
        .scaleEffect(isDragging ? 1.15 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
    }
}

// MARK: - CheckerboardView

private struct CheckerboardView: View {
    private let cellSize: CGFloat = 16

    var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width / cellSize))
            let rows = Int(ceil(size.height / cellSize))

            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let color = isLight
                        ? Color(white: 0.18)
                        : Color(white: 0.12)
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
