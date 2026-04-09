// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Allowed image types

extension UTType {
    static let webP = UTType(importedAs: "org.webmproject.webp")
}

let allowedImageTypes: [UTType] = [.jpeg, .png, .webP]

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showDropZone = true
    @State private var sidebarWidth: CGFloat = 260

    var body: some View {
        HSplitView {
            // Left: history / batch sidebar
            SidebarView()
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)

            // Centre + right: main workspace
            if let doc = appState.selectedDocument {
                WorkspaceView(document: doc)
            } else {
                DropZoneView()
            }
        }
        .background(Color.forgeBg)
        .onChange(of: appState.openPanelTrigger) { _ in openFilePicker() }
        .onChange(of: appState.batchPanelTrigger) { _ in openBatchPicker() }
    }

    // MARK: - File pickers

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.title = "Open Image"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = allowedImageTypes

        if panel.runModal() == .OK, let url = panel.url {
            loadImage(from: url)
        }
    }

    private func openBatchPicker() {
        let panel = NSOpenPanel()
        panel.title = "Open Images for Batch Processing"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = allowedImageTypes

        if panel.runModal() == .OK {
            for url in panel.urls {
                loadImage(from: url)
            }
        }
    }

    private func loadImage(from url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }
        let doc = ImageDocument(url: url, image: image)
        appState.addDocument(doc)
        Task {
            await SegmentationEngine.shared.process(document: doc)
        }
    }
}

// MARK: - WorkspaceView

struct WorkspaceView: View {
    @ObservedObject var document: ImageDocument
    @EnvironmentObject private var appState: AppState
    @State private var showExport = false

    var body: some View {
        HSplitView {
            // Main canvas area
            VStack(spacing: 0) {
                WorkspaceToolbar(document: document, showExport: $showExport)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.forgePanel)

                Divider().background(Color.forgeBorder)

                CompareSliderView(document: document)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.forgeCanvas)
            }

            // Right panel: controls
            RightPanel(document: document, showExport: $showExport)
                .frame(minWidth: 260, idealWidth: 280, maxWidth: 320)
        }
        .sheet(isPresented: $showExport) {
            ExportPanel(document: document)
        }
    }
}

// MARK: - WorkspaceToolbar

struct WorkspaceToolbar: View {
    @ObservedObject var document: ImageDocument
    @Binding var showExport: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayName)
                    .font(.system(.headline, design: .default).weight(.semibold))
                    .foregroundColor(.forgeGold)
                    .lineLimit(1)
                Text(stateLabel)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(stateColor)
            }

            Spacer()

            if document.isProcessing {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(.circular)
                    .tint(.forgeAmber)
            }

            Button {
                reslag()
            } label: {
                Label("Re-Slag", systemImage: "arrow.clockwise.circle.fill")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(ForgeButtonStyle(accent: false))
            .help("Re-run background removal")
            .disabled(document.isProcessing)

            Button {
                showExport = true
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(ForgeButtonStyle(accent: true))
            .disabled(!document.isDone)
        }
    }

    private var stateLabel: String {
        switch document.state {
        case .idle: return "Ready to slag"
        case .processing: return "Slagging..."
        case .done: return "Slagged!"
        case .failed(let msg): return "Failed: \(msg)"
        }
    }

    private var stateColor: Color {
        switch document.state {
        case .idle: return .forgeSubtext
        case .processing: return .forgeAmber
        case .done: return .forgeGold
        case .failed: return .forgeError
        }
    }

    private func reslag() {
        Task {
            await SegmentationEngine.shared.process(document: document)
        }
    }
}

// MARK: - RightPanel

struct RightPanel: View {
    @ObservedObject var document: ImageDocument
    @Binding var showExport: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                EdgeControlsView(document: document)
                    .padding()

                Divider().background(Color.forgeBorder)

                BackgroundPicker(document: document)
                    .padding()

                Divider().background(Color.forgeBorder)

                ExportShortcut(showExport: $showExport, document: document)
                    .padding()
            }
        }
        .background(Color.forgePanel)
    }
}

// MARK: - ExportShortcut (mini export section in right panel)

struct ExportShortcut: View {
    @Binding var showExport: Bool
    @ObservedObject var document: ImageDocument

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Export", icon: "square.and.arrow.up")

            Button {
                showExport = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                    Text("Export Image")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(ForgeButtonStyle(accent: true))
            .disabled(!document.isDone)
        }
    }
}

// MARK: - SidebarView

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Branding header
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundColor(.forgeAmber)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Foundry Slag")
                        .font(.system(.headline, design: .default).weight(.bold))
                        .foregroundColor(.forgeGold)
                    Text("The slag burns away, the gold remains")
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(.forgeSubtext)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.forgePanel)

            Divider().background(Color.forgeBorder)

            // Open buttons
            HStack(spacing: 8) {
                Button {
                    appState.triggerOpenPanel()
                } label: {
                    Label("Open", systemImage: "plus.circle.fill")
                }
                .buttonStyle(ForgeButtonStyle(accent: true))

                Button {
                    appState.triggerBatchPanel()
                } label: {
                    Label("Batch", systemImage: "rectangle.stack.badge.plus")
                }
                .buttonStyle(ForgeButtonStyle(accent: false))
            }
            .padding(12)
            .background(Color.forgePanel)

            Divider().background(Color.forgeBorder)

            if appState.documents.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.largeTitle)
                        .foregroundColor(.forgeSubtext)
                    Text("No images yet")
                        .font(.caption)
                        .foregroundColor(.forgeSubtext)
                }
                Spacer()
            } else {
                List(appState.documents, selection: Binding(
                    get: { appState.selectedDocument?.id },
                    set: { id in
                        if let id {
                            appState.selectedDocument = appState.documents.first { $0.id == id }
                        }
                    }
                )) { doc in
                    DocumentRow(document: doc)
                        .tag(doc.id)
                        .listRowBackground(
                            appState.selectedDocument?.id == doc.id
                                ? Color.forgeAmber.opacity(0.15)
                                : Color.clear
                        )
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .background(Color.forgeBg)
            }
        }
        .background(Color.forgeBg)
    }
}

// MARK: - DocumentRow

struct DocumentRow: View {
    @ObservedObject var document: ImageDocument
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail
            Group {
                if let thumb = document.thumbnailImage {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.forgeSubtext.opacity(0.2))
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.forgeBorder, lineWidth: 0.5)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(document.displayName)
                    .font(.system(.caption, design: .default).weight(.medium))
                    .foregroundColor(.forgeText)
                    .lineLimit(1)

                stateIndicator
            }

            Spacer()

            Button {
                appState.removeDocument(document)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.forgeSubtext)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var stateIndicator: some View {
        switch document.state {
        case .idle:
            Text("Queued")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.forgeSubtext)
        case .processing:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 12, height: 12)
                    .progressViewStyle(.circular)
                    .tint(.forgeAmber)
                Text("Slagging...")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.forgeAmber)
            }
        case .done:
            Text("Slagged!")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.forgeGold)
        case .failed:
            Text("Failed")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.forgeError)
        }
    }
}

// MARK: - Design tokens

extension Color {
    static let forgeBg      = Color(red: 0.078, green: 0.071, blue: 0.063)   // #141210
    static let forgePanel   = Color(red: 0.11, green: 0.10, blue: 0.09)
    static let forgeCanvas  = Color(red: 0.06, green: 0.055, blue: 0.05)
    static let forgeBorder  = Color(red: 0.20, green: 0.18, blue: 0.16)
    static let forgeText    = Color(red: 0.92, green: 0.88, blue: 0.82)
    static let forgeSubtext = Color(red: 0.50, green: 0.46, blue: 0.42)
    static let forgeAmber   = Color(red: 0.910, green: 0.659, blue: 0.286)   // #E8A849
    static let forgeGold    = Color(red: 0.976, green: 0.843, blue: 0.463)   // #F8D776
    static let forgeError   = Color(red: 0.85, green: 0.30, blue: 0.30)
}

// MARK: - Shared sub-views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.forgeAmber)
            Text(title.uppercased())
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .foregroundColor(.forgeSubtext)
                .tracking(1.2)
            Spacer()
        }
    }
}

// MARK: - ExportPanel

struct ExportPanel: View {
    @ObservedObject var document: ImageDocument
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .png
    @State private var exportError: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "square.and.arrow.up.fill")
                    .foregroundColor(.forgeAmber)
                Text("Export Slagged Image")
                    .font(.system(.headline, design: .default).weight(.bold))
                    .foregroundColor(.forgeGold)
                Spacer()
            }

            // Preview
            if let result = document.compositeWithBackground() ?? document.resultImage {
                Image(nsImage: result)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.forgeBorder, lineWidth: 1)
                    )
            }

            // Format picker
            VStack(alignment: .leading, spacing: 8) {
                Text("FORMAT")
                    .font(.system(.caption2, design: .monospaced).weight(.semibold))
                    .foregroundColor(.forgeSubtext)
                    .tracking(1.2)

                Picker("", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            if let err = exportError {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.forgeError)
            }

            Divider().background(Color.forgeBorder)

            // Actions
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(ForgeButtonStyle(accent: false))
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    exportImage()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down.fill")
                }
                .buttonStyle(ForgeButtonStyle(accent: true))
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
        .background(Color.forgePanel)
    }

    private func exportImage() {
        guard let image = document.compositeWithBackground() ?? document.resultImage else {
            exportError = "No processed image available."
            return
        }

        let panel = NSSavePanel()
        panel.title = "Export Image"
        panel.nameFieldStringValue = "\(document.displayName)_slagged.\(selectedFormat.fileExtension)"
        panel.allowedContentTypes = selectedFormat == .png
            ? [.png]
            : [.jpeg]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff)
        else {
            exportError = "Could not convert image for export."
            return
        }

        let data: Data?
        switch selectedFormat {
        case .png:
            data = bitmap.representation(using: .png, properties: [:])
        case .jpg:
            data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        }

        guard let fileData = data else {
            exportError = "Failed to encode image."
            return
        }

        do {
            try fileData.write(to: url)
            dismiss()
        } catch {
            exportError = "Save failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - ForgeButtonStyle

struct ForgeButtonStyle: ButtonStyle {
    let accent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.caption, design: .default).weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                accent
                    ? Color.forgeAmber.opacity(configuration.isPressed ? 0.75 : 1.0)
                    : Color.forgeBorder.opacity(configuration.isPressed ? 0.5 : 1.0)
            )
            .foregroundColor(accent ? Color.forgeBg : Color.forgeText)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
