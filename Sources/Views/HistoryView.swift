// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI

// MARK: - HistoryView

/// Displays the processing history as a searchable, filterable list.
struct HistoryView: View {
    @ObservedObject var historyStore: HistoryStore
    @State private var searchText = ""
    @State private var selectedEntry: SlagImage?
    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HistoryHeader(
                entryCount: filteredEntries.count,
                showClearConfirm: $showClearConfirm
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.forgePanel)

            Divider().background(Color.forgeBorder)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.forgeSubtext)
                    .font(.caption)
                TextField("Search history...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(.caption, design: .default))
                    .foregroundColor(.forgeText)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.forgeSubtext)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.forgePanel.opacity(0.5))

            Divider().background(Color.forgeBorder)

            // Entries list
            if filteredEntries.isEmpty {
                HistoryEmptyState(hasSearch: !searchText.isEmpty)
            } else {
                List(filteredEntries, selection: $selectedEntry) { entry in
                    HistoryRow(entry: entry) {
                        historyStore.removeEntry(id: entry.id)
                    }
                    .tag(entry)
                    .listRowBackground(
                        selectedEntry?.id == entry.id
                            ? Color.forgeAmber.opacity(0.12)
                            : Color.clear
                    )
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.forgeBg)
            }
        }
        .alert("Clear History", isPresented: $showClearConfirm) {
            Button("Clear All", role: .destructive) {
                historyStore.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all history entries. This cannot be undone.")
        }
    }

    // MARK: - Filtering

    private var filteredEntries: [SlagImage] {
        if searchText.isEmpty {
            return historyStore.entries
        }
        let query = searchText.lowercased()
        return historyStore.entries.filter { entry in
            entry.originalFileName.lowercased().contains(query) ||
            entry.modelUsed.lowercased().contains(query) ||
            entry.status.displayLabel.lowercased().contains(query)
        }
    }
}

// MARK: - HistoryHeader

private struct HistoryHeader: View {
    let entryCount: Int
    @Binding var showClearConfirm: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.title3)
                .foregroundColor(.forgeAmber)

            VStack(alignment: .leading, spacing: 2) {
                Text("History")
                    .font(.system(.headline, design: .default).weight(.bold))
                    .foregroundColor(.forgeGold)
                Text("\(entryCount) entries")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.forgeSubtext)
            }

            Spacer()

            if entryCount > 0 {
                Button {
                    showClearConfirm = true
                } label: {
                    Label("Clear", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(ForgeButtonStyle(accent: false))
                .help("Clear all history")
            }
        }
    }
}

// MARK: - HistoryRow

private struct HistoryRow: View {
    let entry: SlagImage
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon
                .frame(width: 28, height: 28)
                .background(statusColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.displayName)
                    .font(.system(.caption, design: .default).weight(.medium))
                    .foregroundColor(.forgeText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(entry.formattedDate)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.forgeSubtext)

                    if entry.processingTimeMs > 0 {
                        Text(entry.formattedProcessingTime)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.forgeAmber)
                    }

                    Text(entry.modelUsed)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.forgeSubtext)
                }
            }

            Spacer()

            // Status label
            Text(entry.status.displayLabel)
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .foregroundColor(statusColor)

            // Delete
            Button {
                onDelete()
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
    private var statusIcon: some View {
        switch entry.status {
        case .queued:
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.forgeSubtext)
        case .slagging:
            Image(systemName: "flame")
                .font(.caption)
                .foregroundColor(.forgeAmber)
        case .slagged:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.forgeGold)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.forgeError)
        }
    }

    private var statusColor: Color {
        switch entry.status {
        case .queued: return .forgeSubtext
        case .slagging: return .forgeAmber
        case .slagged: return .forgeGold
        case .failed: return .forgeError
        }
    }
}

// MARK: - HistoryEmptyState

private struct HistoryEmptyState: View {
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: hasSearch ? "magnifyingglass" : "clock")
                .font(.system(size: 40))
                .foregroundColor(.forgeSubtext)

            Text(hasSearch ? "No matching entries" : "No history yet")
                .font(.system(.callout, design: .default).weight(.medium))
                .foregroundColor(.forgeText)

            Text(hasSearch
                 ? "Try a different search term"
                 : "Slagged images will appear here")
                .font(.caption)
                .foregroundColor(.forgeSubtext)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.forgeBg)
    }
}

// MARK: - SlagImage + Hashable for selection

extension SlagImage: Hashable {
    static func == (lhs: SlagImage, rhs: SlagImage) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
