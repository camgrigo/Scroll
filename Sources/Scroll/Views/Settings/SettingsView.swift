import SwiftUI

// MARK: - SettingsView

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var tabManager: TabManager
    @StateObject private var autoDownload = AutoDownloadService()

    // Appearance
    @AppStorage("colorSchemePreference") private var colorSchemePref: String = "system"
    // Extra highlight colors
    @AppStorage("extraHighlightsEnabled") private var extraHighlights: Bool = false

    var body: some View {
        NavigationStack {
            List {

                // MARK: Tabs
                Section {
                    Toggle(isOn: $tabManager.autoCloseEnabled) {
                        Label("Auto-close tabs after 1 day", systemImage: "clock.arrow.circlepath")
                    }
                    .tint(AppTheme.accent)
                } header: {
                    sectionHeader("Tabs")
                }
                .listRowBackground(AppTheme.surface)

                // MARK: Auto Downloads
                Section {
                    Toggle(isOn: $autoDownload.enabled) {
                        Label("Enable auto-downloads", systemImage: "arrow.down.circle")
                    }
                    .tint(AppTheme.accent)

                    if autoDownload.enabled {
                        Toggle(isOn: $autoDownload.wifiOnly) {
                            Label("Wi-Fi only", systemImage: "wifi")
                        }
                        .tint(AppTheme.accent)

                        Toggle(isOn: $autoDownload.downloadMeetingMaterials) {
                            Label("Download meeting materials", systemImage: "person.3")
                        }
                        .tint(AppTheme.accent)

                        Toggle(isOn: $autoDownload.downloadWatchtower) {
                            Label("Download Watchtower", systemImage: "magazine")
                        }
                        .tint(AppTheme.accent)

                        Button {
                            Task { await autoDownload.downloadCurrentWeekMaterials() }
                        } label: {
                            Label("Download now", systemImage: "icloud.and.arrow.down")
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                } header: {
                    sectionHeader("Auto Downloads")
                }
                .listRowBackground(AppTheme.surface)

                // MARK: Highlights
                Section {
                    // Color preview
                    HStack(spacing: 8) {
                        ForEach(AppTheme.highlightColors, id: \.name) { item in
                            Circle()
                                .fill(item.color)
                                .frame(width: 24, height: 24)
                        }
                        Spacer()
                    }

                    Toggle(isOn: $extraHighlights) {
                        Label("Show extra colors (green, teal, gray)", systemImage: "paintpalette")
                    }
                    .tint(AppTheme.accent)
                } header: {
                    sectionHeader("Highlights")
                }
                .listRowBackground(AppTheme.surface)

                // MARK: Appearance
                Section {
                    Picker(selection: $colorSchemePref) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.accent)
                } header: {
                    sectionHeader("Appearance")
                }
                .listRowBackground(AppTheme.surface)

                // MARK: About
                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(AppTheme.text)
                        Spacer()
                        Text(appVersion())
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Link(destination: URL(string: "https://www.jw.org/en/terms-of-use/")!) {
                        Label("JW.ORG Terms of Use", systemImage: "doc.text")
                            .foregroundStyle(AppTheme.accent)
                    }

                    Link(destination: URL(string: "https://www.jw.org/en/privacy-policy/")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                            .foregroundStyle(AppTheme.accent)
                    }

                    Label("Not an official JW.ORG product", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                } header: {
                    sectionHeader("About")
                }
                .listRowBackground(AppTheme.surface)
            }
#if os(iOS)
            .listStyle(.insetGrouped)
#else
            .listStyle(.inset)
#endif
            .scrollContentBackground(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.uppercaseSmallCaps())
            .foregroundStyle(AppTheme.textSecondary)
    }

    private func appVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
