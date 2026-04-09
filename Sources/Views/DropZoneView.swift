// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isDragTargeted = false
    @State private var dropError: String?

    var body: some View {
        ZStack {
            Color.forgeCanvas

            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.forgeAmber.opacity(isDragTargeted ? 0.20 : 0.10))
                        .frame(width: 100, height: 100)
                    Image(systemName: isDragTargeted ? "flame.fill" : "photo.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(isDragTargeted ? .forgeGold : .forgeAmber)
                        .animation(.easeInOut(duration: 0.15), value: isDragTargeted)
                }

                VStack(spacing: 8) {
                    Text(isDragTargeted ? "Drop to Slag" : "Slag an Image")
                        .font(.system(.title2, design: .default).weight(.bold))
                        .foregroundColor(.forgeGold)

                    Text("Drag & drop or click to open JPG, PNG, or WebP")
                        .font(.system(.callout, design: .default))
                        .foregroundColor(.forgeSubtext)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    Button {
                        appState.triggerOpenPanel()
                    } label: {
                        Label("Open Image", systemImage: "photo")
                    }
                    .buttonStyle(ForgeButtonStyle(accent: true))

                    Button {
                        appState.triggerBatchPanel()
                    } label: {
                        Label("Open Batch", systemImage: "rectangle.stack.badge.plus")
                    }
                    .buttonStyle(ForgeButtonStyle(accent: false))
                }

                if let err = dropError {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.forgeError)
                }

                Spacer().frame(height: 20)

                Text("The slag burns away, the gold remains")
                    .font(.system(.caption, design: .default).italic())
                    .foregroundColor(.forgeSubtext.opacity(0.6))
            }
            .padding(40)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isDragTargeted ? Color.forgeAmber : Color.forgeBorder,
                    style: StrokeStyle(lineWidth: isDragTargeted ? 2.5 : 1.5, dash: [8, 6])
                )
                .padding(20)
                .animation(.easeInOut(duration: 0.15), value: isDragTargeted)
        )
        .onDrop(of: allowedImageTypes, isTargeted: $isDragTargeted) { providers in
            handleDrop(providers: providers)
        }
        .contentShape(Rectangle())
    }

    // MARK: - Drop handling

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        dropError = nil
        var handled = false

        for provider in providers {
            // Try each allowed type
            for type in allowedImageTypes {
                if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                    provider.loadDataRepresentation(forTypeIdentifier: type.identifier) { data, error in
                        DispatchQueue.main.async {
                            guard let data, let image = NSImage(data: data) else {
                                self.dropError = "Could not read dropped file."
                                return
                            }
                            // Try to get a file URL for the name
                            let url = FileManager.default.temporaryDirectory.appendingPathComponent("dropped_image.\(type.preferredFilenameExtension ?? "png")")
                            let doc = ImageDocument(url: url, image: image)
                            self.appState.addDocument(doc)
                            Task {
                                await SegmentationEngine.shared.process(document: doc)
                            }
                        }
                    }
                    handled = true
                    break
                }
            }

            // Also accept file URLs directly
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    DispatchQueue.main.async {
                        guard let data = item as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil),
                              let image = NSImage(contentsOf: url)
                        else { return }
                        let doc = ImageDocument(url: url, image: image)
                        self.appState.addDocument(doc)
                        Task {
                            await SegmentationEngine.shared.process(document: doc)
                        }
                    }
                }
                handled = true
            }
        }

        return handled
    }
}
