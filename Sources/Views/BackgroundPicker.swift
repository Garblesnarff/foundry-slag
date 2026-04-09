// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI
import UniformTypeIdentifiers

struct BackgroundPicker: View {
    @ObservedObject var document: ImageDocument

    @State private var solidColor: Color = .white
    @State private var showColorPanel = false
    @State private var selectedMode: BGModeTab = .transparent

    private enum BGModeTab: String, CaseIterable {
        case transparent = "Transparent"
        case color = "Color"
        case image = "Image"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Background", icon: "square.3.layers.3d")

            // Tab picker
            Picker("", selection: $selectedMode) {
                ForEach(BGModeTab.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: selectedMode) { mode in
                applyMode(mode)
            }

            // Mode-specific controls
            switch selectedMode {
            case .transparent:
                TransparentBGInfo()

            case .color:
                ColorBGControls(
                    color: $solidColor,
                    showColorPanel: $showColorPanel
                )
                .onChange(of: solidColor) { color in
                    document.backgroundMode = .color(NSColor(color))
                }

            case .image:
                ImageBGControls { url in
                    document.backgroundMode = .image(url)
                }
            }
        }
        .onAppear {
            // Sync tab to current document mode
            switch document.backgroundMode {
            case .transparent: selectedMode = .transparent
            case .color(let c): selectedMode = .color; solidColor = Color(c)
            case .image: selectedMode = .image
            }
        }
    }

    private func applyMode(_ mode: BGModeTab) {
        switch mode {
        case .transparent:
            document.backgroundMode = .transparent
        case .color:
            document.backgroundMode = .color(NSColor(solidColor))
        case .image:
            break // handled when user picks an image
        }
    }
}

// MARK: - TransparentBGInfo

private struct TransparentBGInfo: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.forgeGold)
                .font(.callout)
            Text("Exports with full transparency (PNG only)")
                .font(.system(.caption, design: .default))
                .foregroundColor(.forgeSubtext)
        }
    }
}

// MARK: - ColorBGControls

private struct ColorBGControls: View {
    @Binding var color: Color
    @Binding var showColorPanel: Bool

    // Common quick-pick colors
    private let quickColors: [Color] = [
        .white,
        Color(red: 0.95, green: 0.95, blue: 0.95),
        Color(red: 0.1, green: 0.1, blue: 0.1),
        .black,
        Color(red: 0.18, green: 0.47, blue: 0.81),
        Color(red: 0.22, green: 0.65, blue: 0.35),
        Color(red: 0.85, green: 0.23, blue: 0.22),
        Color(red: 0.91, green: 0.66, blue: 0.29)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Quick picks
            HStack(spacing: 8) {
                ForEach(quickColors.indices, id: \.self) { idx in
                    Circle()
                        .fill(quickColors[idx])
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(
                                    color == quickColors[idx]
                                        ? Color.forgeAmber
                                        : Color.forgeBorder,
                                    lineWidth: color == quickColors[idx] ? 2 : 1
                                )
                        )
                        .onTapGesture { color = quickColors[idx] }
                }
                Spacer()
            }

            // Full color picker
            HStack(spacing: 8) {
                ColorPicker("Custom", selection: $color, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 28, height: 28)

                Text("Custom color")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(.forgeSubtext)

                Spacer()

                // Hex preview
                Text(hexString(from: NSColor(color)))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.forgeAmber)
            }
        }
    }

    private func hexString(from color: NSColor) -> String {
        guard let srgb = color.usingColorSpace(.sRGB) else { return "#------" }
        let r = Int(srgb.redComponent * 255)
        let g = Int(srgb.greenComponent * 255)
        let b = Int(srgb.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - ImageBGControls

private struct ImageBGControls: View {
    let onImageSelected: (URL) -> Void
    @State private var selectedImageURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let url = selectedImageURL {
                HStack(spacing: 8) {
                    if let img = NSImage(contentsOf: url) {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.forgeBorder))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(url.lastPathComponent)
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.forgeText)
                            .lineLimit(1)
                        Button("Change") { pickImage() }
                            .buttonStyle(.plain)
                            .font(.system(.caption2, design: .default))
                            .foregroundColor(.forgeAmber)
                    }
                    Spacer()
                }
            } else {
                Button {
                    pickImage()
                } label: {
                    HStack {
                        Image(systemName: "photo.badge.plus")
                        Text("Choose Background Image")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(ForgeButtonStyle(accent: false))
            }

            Text("JPG, PNG, or WebP. Will be scaled to fit.")
                .font(.system(.caption2, design: .default))
                .foregroundColor(.forgeSubtext)
        }
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.title = "Choose Background Image"
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.jpeg, .png, .webP]
        if panel.runModal() == .OK, let url = panel.url {
            selectedImageURL = url
            onImageSelected(url)
        }
    }
}
