// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - BatchView

/// Batch processing view showing a grid of images with individual progress,
/// an overall progress bar, and batch export controls.
struct BatchView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Batch header
            BatchHeader(
                total: appState.documents.count,
                completed: completedCount,
                showFilePicker: $showFilePicker
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.forgePanel)

            Divider().background(Color.forgeBorder)

            // Overall progress
            if isAnyProcessing {
                BatchProgressBar(
                    completed: completedCount,
                    total: appState.documents.count
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.forgePanel.opacity(0.7))

                Divider().background(Color.forgeBorder)
            }

            // Content
            if appState.documents.isEmpty {
                BatchEmptyState(showFilePicker: $showFilePicker)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 180, maximum: 220), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(appState.documents) { doc in
                            BatchImageCard(document: doc)
                                .onTapGesture {
                                    appState.selectedDocument = doc
                                    appState.isBatchMode = false
                                }
                        }
                    }
                    .padding(16)
                }
                .background(Color.forgeBg)
            }

            Divider().background(Color.forgeBorder)

            // Batch actions
            BatchActions(documents: appState.documents)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.forgePanel)
        }
        .onChange(of: showFilePicker) { _ in
            if showFilePicker {
                openBatchPicker()
                showFilePicker = false
            }
        }
    }

    // MARK: - Computed

    private var completedCount: Int {
        appState.documents.filter(\.isDone).count
    }

    private var isAnyProcessing: Bool {
        appState.documents.contains(where: \.isProcessing)
    }

    // MARK: - File Picker

    private func openBatchPicker() {
        let panel = NSOpenPanel()
        panel.title = "Select Images for Batch Slagging"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = allowedImageTypes

        if panel.runModal() == .OK {
            for url in panel.urls {
                guard let image = NSImage(contentsOf: url) else { continue }
                let doc = ImageDocument(url: url, image: image)
                appState.addDocument(doc)
                Task {
                    await SegmentationEngine.shared.process(document: doc)
                }
            }
        }
    }
}

// MARK: - BatchHeader

private struct BatchHeader: View {
    let total: Int
    let completed: Int
    @Binding var showFilePicker: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.stack.fill")
                .font(.title3)
                .foregroundColor(.forgeAmber)

            VStack(alignment: .leading, spacing: 2) {
                Text("Batch Slagging")
                    .font(.system(.headline, design: .default).weight(.bold))
                    .foregroundColor(.forgeGold)
                Text("\(completed)/\(total) slagged")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.forgeSubtext)
            }

            Spacer()

            Button {
                showFilePicker = true
            } label: {
                Label("Add More", systemImage: "plus.circle.fill")
            }
            .buttonStyle(ForgeButtonStyle(accent: true))
        }
    }
}

// MARK: - BatchProgressBar

private struct BatchProgressBar: View {
    let completed: Int
    let total: Int

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Slagging batch...")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.forgeAmber)
                Spacer()
                Text("\(Int(fraction * 100))%")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.forgeGold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.forgeBorder)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.forgeAmber)
                        .frame(width: geo.size.width * fraction)
                        .animation(.easeInOut(duration: 0.3), value: fraction)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - BatchEmptyState

private struct BatchEmptyState: View {
    @Binding var showFilePicker: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.forgeSubtext)

            VStack(spacing: 8) {
                Text("No images in batch")
                    .font(.system(.title3, design: .default).weight(.semibold))
                    .foregroundColor(.forgeText)

                Text("Add images to slag them all at once")
                    .font(.callout)
                    .foregroundColor(.forgeSubtext)
            }

            Button {
                showFilePicker = true
            } label: {
                Label("Add Images", systemImage: "plus.circle.fill")
            }
            .buttonStyle(ForgeButtonStyle(accent: true))

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.forgeBg)
    }
}

// MARK: - BatchImageCard

private struct BatchImageCard: View {
    @ObservedObject var document: ImageDocument

    var body: some View {
        VStack(spacing: 0) {
            // Thumbnail
            ZStack {
                if let thumb = document.thumbnailImage {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.forgeSubtext.opacity(0.1))
                }

                // Processing overlay
                if document.isProcessing {
                    Color.forgeBg.opacity(0.6)
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.forgeAmber)
                        Text("Slagging...")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.forgeAmber)
                    }
                }
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            // Info bar
            HStack(spacing: 6) {
                stateIcon
                Text(document.displayName)
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(.forgeText)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .background(Color.forgePanel)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch document.state {
        case .idle:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundColor(.forgeSubtext)
        case .processing:
            Image(systemName: "flame")
                .font(.caption2)
                .foregroundColor(.forgeAmber)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.forgeGold)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundColor(.forgeError)
        }
    }

    private var borderColor: Color {
        switch document.state {
        case .done: return .forgeGold.opacity(0.3)
        case .processing: return .forgeAmber.opacity(0.4)
        case .failed: return .forgeError.opacity(0.3)
        default: return .forgeBorder
        }
    }
}

// MARK: - BatchActions

private struct BatchActions: View {
    let documents: [ImageDocument]
    @State private var isExporting = false

    private var allDone: Bool {
        !documents.isEmpty && documents.allSatisfy(\.isDone)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text("\(documents.count) images")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.forgeSubtext)

            Spacer()

            Button {
                exportBatchAsZip()
            } label: {
                Label("Export All as ZIP", systemImage: "archivebox.fill")
            }
            .buttonStyle(ForgeButtonStyle(accent: true))
            .disabled(!allDone)
        }
    }

    private func exportBatchAsZip() {
        let panel = NSSavePanel()
        panel.title = "Export Batch"
        panel.nameFieldStringValue = "slagged_batch.zip"
        panel.allowedContentTypes = [.zip]

        guard panel.runModal() == .OK, let _ = panel.url else { return }
        // ZIP export would be implemented here
    }
}
