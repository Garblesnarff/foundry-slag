// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI

struct EdgeControlsView: View {
    @ObservedObject var document: ImageDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Edge Refinement", icon: "wand.and.stars")

            // Feather slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Feather")
                        .font(.system(.caption, design: .default).weight(.medium))
                        .foregroundColor(.forgeText)
                    Spacer()
                    Text(String(format: "%.1fpx", document.featherRadius))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.forgeAmber)
                        .frame(minWidth: 42, alignment: .trailing)
                }

                ForgeSlider(
                    value: $document.featherRadius,
                    range: 0...20,
                    step: 0.5
                )

                Text("Softens hard edges for a more natural cutout")
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(.forgeSubtext)
            }

            Divider().background(Color.forgeBorder)

            // Edge shift slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Edge Shift")
                        .font(.system(.caption, design: .default).weight(.medium))
                        .foregroundColor(.forgeText)
                    Spacer()
                    Text(String(format: "%+.1fpx", document.edgeShift))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(shiftColor)
                        .frame(minWidth: 50, alignment: .trailing)
                }

                ForgeSlider(
                    value: $document.edgeShift,
                    range: -10...10,
                    step: 0.5
                )

                HStack {
                    Text("Contract")
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(.forgeSubtext)
                    Spacer()
                    Text("Expand")
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(.forgeSubtext)
                }

                Text("Shrinks or expands the subject boundary")
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(.forgeSubtext)
            }

            // Reset button
            HStack {
                Spacer()
                Button {
                    document.featherRadius = 2.0
                    document.edgeShift = 0.0
                } label: {
                    Text("Reset Edges")
                }
                .buttonStyle(ForgeButtonStyle(accent: false))
            }
        }
    }

    private var shiftColor: Color {
        if document.edgeShift > 0 { return .forgeGold }
        if document.edgeShift < 0 { return .forgeAmber }
        return .forgeSubtext
    }
}

// MARK: - ForgeSlider

struct ForgeSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        Slider(value: $value, in: range, step: step)
            .tint(.forgeAmber)
            .controlSize(.small)
    }
}
