// Copyright © 2026 Hanson Foundry. All rights reserved.

import SwiftUI

// MARK: - SettingsView

/// Model and export settings panel.
struct SettingsView: View {
    @AppStorage("defaultExportFormat") private var defaultExportFormat = "PNG"
    @AppStorage("defaultFeatherRadius") private var defaultFeatherRadius: Double = 2.0
    @AppStorage("defaultEdgeShift") private var defaultEdgeShift: Double = 0.0
    @AppStorage("autoProcessOnDrop") private var autoProcessOnDrop = true

    @State private var showResetConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(.forgeAmber)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Settings")
                        .font(.system(.headline, design: .default).weight(.bold))
                        .foregroundColor(.forgeGold)
                    Text("Configure the forge")
                        .font(.system(.caption, design: .default))
                        .foregroundColor(.forgeSubtext)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.forgePanel)

            Divider().background(Color.forgeBorder)

            ScrollView {
                VStack(spacing: 0) {
                    // Model section
                    SettingsSection(title: "Model", icon: "cpu") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Engine")
                                    .font(.system(.caption, design: .default).weight(.medium))
                                    .foregroundColor(.forgeText)
                                Spacer()
                                Text("Apple Vision")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.forgeAmber)
                            }

                            Text("Uses VNGenerateForegroundInstanceMaskRequest on macOS 14+ with person segmentation fallback on macOS 13.")
                                .font(.system(.caption2, design: .default))
                                .foregroundColor(.forgeSubtext)

                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption2)
                                    .foregroundColor(.forgeGold)
                                Text("100% on-device • No cloud • No subscriptions")
                                    .font(.system(.caption2, design: .default))
                                    .foregroundColor(.forgeSubtext)
                            }
                        }
                    }

                    // Export defaults
                    SettingsSection(title: "Export Defaults", icon: "square.and.arrow.up") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Default Format")
                                    .font(.system(.caption, design: .default).weight(.medium))
                                    .foregroundColor(.forgeText)

                                Picker("", selection: $defaultExportFormat) {
                                    Text("PNG").tag("PNG")
                                    Text("JPG").tag("JPG")
                                }
                                .pickerStyle(.segmented)
                                .labelsHidden()
                            }
                        }
                    }

                    // Edge defaults
                    SettingsSection(title: "Edge Defaults", icon: "wand.and.stars") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Default Feather")
                                        .font(.system(.caption, design: .default).weight(.medium))
                                        .foregroundColor(.forgeText)
                                    Spacer()
                                    Text(String(format: "%.1fpx", defaultFeatherRadius))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.forgeAmber)
                                }
                                Slider(value: $defaultFeatherRadius, in: 0...20, step: 0.5)
                                    .tint(.forgeAmber)
                                    .controlSize(.small)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Default Edge Shift")
                                        .font(.system(.caption, design: .default).weight(.medium))
                                        .foregroundColor(.forgeText)
                                    Spacer()
                                    Text(String(format: "%+.1fpx", defaultEdgeShift))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.forgeAmber)
                                }
                                Slider(value: $defaultEdgeShift, in: -10...10, step: 0.5)
                                    .tint(.forgeAmber)
                                    .controlSize(.small)
                            }
                        }
                    }

                    // Behavior
                    SettingsSection(title: "Behavior", icon: "bolt") {
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $autoProcessOnDrop) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto-process on drop")
                                        .font(.system(.caption, design: .default).weight(.medium))
                                        .foregroundColor(.forgeText)
                                    Text("Automatically slag images when dropped onto the forge")
                                        .font(.system(.caption2, design: .default))
                                        .foregroundColor(.forgeSubtext)
                                }
                            }
                            .toggleStyle(.switch)
                            .tint(.forgeAmber)
                        }
                    }

                    // About
                    SettingsSection(title: "About", icon: "flame.fill") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Foundry Slag")
                                    .font(.system(.caption, design: .default).weight(.semibold))
                                    .foregroundColor(.forgeGold)
                                Spacer()
                                Text("v1.0.0")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.forgeSubtext)
                            }

                            Text("The slag burns away, the gold remains.")
                                .font(.system(.caption, design: .default).italic())
                                .foregroundColor(.forgeSubtext)

                            Text("© 2026 Hanson Foundry. All rights reserved.")
                                .font(.system(.caption2, design: .default))
                                .foregroundColor(.forgeSubtext.opacity(0.6))
                        }
                    }

                    // Reset
                    HStack {
                        Spacer()
                        Button {
                            showResetConfirm = true
                        } label: {
                            Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(ForgeButtonStyle(accent: false))
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Color.forgeBg)
        }
        .alert("Reset Settings", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                resetDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore all settings to their default values.")
        }
    }

    private func resetDefaults() {
        defaultExportFormat = "PNG"
        defaultFeatherRadius = 2.0
        defaultEdgeShift = 0.0
        autoProcessOnDrop = true
    }
}

// MARK: - SettingsSection

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, icon: icon)
            content()
        }
        .padding(16)

        Divider()
            .background(Color.forgeBorder)
            .padding(.horizontal, 16)
    }
}
